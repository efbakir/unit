#!/bin/sh
# Static source guard; no Xcode, Simulator, network, or third-party packages.
set -eu
cd "$(dirname "$0")/.."
exec python3 - "$@" <<'PY'
import pathlib
import re
import subprocess
import sys
import tempfile

DS = 'Unit/UI/DesignSystem.swift'
WIDGET = 'UnitWidget/RestTimerLiveActivity.swift'
SPLASH = 'Unit/Features/Onboarding/OnboardingSplashView.swift'
OWNERS = {'color': 'AppColor', 'animation': 'AppMotion', 'haptic': 'AppHaptic'}


def code_only(source):
    """Mask comments and Swift strings, preserving offsets/newlines for diagnostics.

    This is a source lint, not a Swift compiler. Raw and multiline strings and
    nested block comments are masked so examples and documentation aren't code.
    """
    chars = list(source)
    i = 0
    def mask(a, b):
        for j in range(a, b):
            if chars[j] != '\n': chars[j] = ' '
    while i < len(source):
        start = i
        if source.startswith('//', i):
            i = source.find('\n', i)
            if i < 0: i = len(source)
        elif source.startswith('/*', i):
            depth = 1
            i += 2
            while i < len(source) and depth:
                if source.startswith('/*', i): depth += 1; i += 2
                elif source.startswith('*/', i): depth -= 1; i += 2
                else: i += 1
        else:
            match = re.match(r'(#{0,})((?:""")|")', source[i:])
            if not match:
                i += 1
                continue
            hashes, quotes = match.groups()
            i += len(match.group())
            terminator = quotes + hashes
            while i < len(source):
                if source.startswith('\\' + hashes, i): i += len(hashes) + 2
                elif source.startswith(terminator, i): i += len(terminator); break
                else: i += 1
        mask(start, min(i, len(source)))
    return ''.join(chars)


def owner_ranges(code, name):
    ranges = []
    for match in re.finditer(r'\benum\s+' + name + r'\b[^{}]*\{', code):
        depth, end = 1, match.end()
        while end < len(code) and depth:
            if code[end] == '{': depth += 1
            elif code[end] == '}': depth -= 1
            end += 1
        if depth: raise ValueError('unclosed owner ' + name)
        ranges.append((match.start(), end))
    return ranges


COLOR_NAMES = r'(?:black|white|gray|red|green|blue|orange|yellow|pink|purple|brown|cyan|mint|indigo|teal|clear|primary|secondary|accentColor)'
ANIMATIONS = r'(?:spring|interactiveSpring|interpolatingSpring|bouncy|snappy|smooth|easeIn|easeOut|easeInOut|linear|timingCurve)'
RULES = [
    ('color', r'\b(?:SwiftUI\s*\.\s*)?Color\s*\('),
    ('color', r'\b(?:UI)?Color\s*\.\s*' + COLOR_NAMES + r'\b'),
    ('color', r'\bUIColor\s*\((?!\s*AppColor\s*\.)'),
    ('color', r'\bUIColor\s*\.\s*[A-Za-z_]\w*'),
    ('color', r':\s*(?:UI)?Color\s*=\s*\.\s*' + COLOR_NAMES + r'\b'),
    ('color', r'\b0x(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\b'),
    ('color', r'\.\s*(?:foregroundStyle|foregroundColor|background|tint|fill|stroke|strokeBorder|keylineTint)\s*\(\s*\.\s*' + COLOR_NAMES + r'\b'),
    ('color', r'\bcolor\s*:\s*\.\s*' + COLOR_NAMES + r'\b'),
    ('animation', r'\.\s*' + ANIMATIONS + r'\s*\('),
    ('animation', r'\bAnimation\s*\('),
    ('animation', r'\bAnimation\s*\.\s*(?:default|' + ANIMATIONS + r')\b'),
    ('animation', r'(?:\.animation|\bwithAnimation)\s*\(\s*\.\s*' + ANIMATIONS + r'\b'),
    ('animation', r'\bwithAnimation\s*(?:\{|\(\s*\))'),
    ('animation', r'\bwithAnimation\s*\(\s*\.default\b'),
    ('animation', r'\.animation\s*\(\s*\.default\b'),
    ('haptic', r'\b(?:UIImpactFeedbackGenerator|UISelectionFeedbackGenerator|UINotificationFeedbackGenerator|CHHapticEngine|CHHapticPattern|CHHapticEvent)\b'),
    ('haptic', r'\bsensoryFeedback\s*\('),
    ('haptic', r'\bSensoryFeedback\s*\.\s*\w+'),
    ('haptic', r':\s*SensoryFeedback\s*=\s*\.'),
    ('haptic', r'\b(?:AudioServicesPlaySystemSound|kSystemSoundID_Vibrate)\b'),
]


def scan(root):
    files = subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z', '--', 'Unit', 'UnitWidget']).decode().split('\0')
    files = [f for f in files if f.endswith('.swift')]
    failures = []
    if not files: return ['No tracked Unit/UnitWidget Swift sources found']
    if DS not in files or not (root / DS).exists():
        failures.append('Missing tracked design-system owner: ' + DS)
    for file in files:
        path = root / file
        if not path.exists(): continue  # tracked deletion in this working tree
        source = path.read_text()
        code = code_only(source)
        ranges = {}
        for kind, owner in OWNERS.items():
            spans = owner_ranges(code, owner)
            if file == DS:
                if len(spans) != 1: failures.append(f'{file}: expected exactly one enum {owner}')
                ranges[kind] = spans
            elif spans:
                failures.append(f'{file}: {owner} must be owned only by {DS}')
        def allowed(kind, offset):
            return any(a <= offset < b for a, b in ranges.get(kind, []))
        for kind, pattern in RULES:
            for match in re.finditer(pattern, code):
                if allowed(kind, match.start()): continue
                # System-rendered Live Activity uses native contrast, not app palette.
                if file == WIDGET and re.fullmatch(r'\.(?:foregroundStyle\s*\(\s*\.(?:primary|secondary)|keylineTint\s*\(\s*\.primary)', match.group()):
                    continue
                line = code.count('\n', 0, match.start()) + 1
                failures.append(f'{file}:{line}: raw {kind}: {match.group().strip()} — use {OWNERS[kind]}')
        if file == 'Unit/ContentView.swift' and re.search(r'\.appHaptic\s*\([^)]*trigger\s*:\s*selectedTab\b', code):
            failures.append(f'{file}: native tab navigation must stay haptically quiet')
        # Only the recorded transient opener can request dark appearance.
        for match in re.finditer(r'\.preferredColorScheme\s*\([^)]*\bdark\b[^)]*\)', code):
            if file == SPLASH and re.sub(r'\s+', '', match.group()) == '.preferredColorScheme(openerVisible?.dark:.light)': continue
            failures.append(f'{file}:{code.count(chr(10), 0, match.start()) + 1}: unapproved dark appearance')
    return sorted(set(failures))


def self_test():
    """Mutate tracked temp fixtures; never modify the caller's working tree."""
    with tempfile.TemporaryDirectory(prefix='unit-guard-') as temp:
        root = pathlib.Path(temp)
        subprocess.run(['git', 'init', '-q', temp], check=True)
        baseline = 'enum AppColor { static let ink = Color(red: 0, green: 0, blue: 0) }\nenum AppMotion { static let move = Animation.spring(duration: 0.2) }\nenum AppHaptic { func fire() { UISelectionFeedbackGenerator().selectionChanged() } }\n'
        fixtures = {
            DS: baseline,
            'Unit/Features/Fixture.swift': 'let c = AppColor.ink\nlet bridge = UIColor(AppColor.ink)\nwithAnimation(.appReveal) { value = 1 }\n// Color.red\nlet text = "Color.blue"\n/* outer /* Animation.spring() */ Color.black */\n',
            WIDGET: 'view.foregroundStyle(.primary).keylineTint(.primary)\n',
            SPLASH: 'view.preferredColorScheme(openerVisible ? .dark : .light)\n',
            'Unit/ContentView.swift': 'TabView { content }\n',
        }
        for file, text in fixtures.items():
            path = root / file; path.parent.mkdir(parents=True, exist_ok=True); path.write_text(text)
        subprocess.run(['git', '-C', temp, 'add', '.'], check=True)
        assert not scan(root), scan(root)
        cases = [
            ('Unit/Features/Fixture.swift', 'let c = Color(\nred: 1, green: 0, blue: 0)'),
            ('Unit/Features/Fixture.swift', 'let c = UIColor(red: 1, green: 0, blue: 0, alpha: 1)'),
            ('Unit/Features/Fixture.swift', 'view.foregroundStyle(\n .red)'),
            ('Unit/Features/Fixture.swift', 'let c = 0xFFFFFF'),
            ('Unit/Features/Fixture.swift', 'let c: Color = .red'),
            ('Unit/Features/Fixture.swift', 'let c = UIColor.systemRed'),
            ('Unit/Features/Fixture.swift', 'view.animation(.easeOut, value: value)'),
            ('Unit/Features/Fixture.swift', 'let a = Animation.default'),
            ('Unit/Features/Fixture.swift', 'withAnimation { value = 1 }'),
            ('Unit/Features/Fixture.swift', 'view.animation(.default, value: value)'),
            ('Unit/Features/Fixture.swift', 'view.animation(.spring(\n duration: 0.2), value: value)'),
            ('Unit/Features/Fixture.swift', 'view.sensoryFeedback(.success, trigger: value)'),
            ('Unit/Features/Fixture.swift', 'UIImpactFeedbackGenerator().impactOccurred()'),
            ('Unit/Features/Fixture.swift', 'let feedback: SensoryFeedback = .success'),
            ('Unit/Features/Fixture.swift', 'AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)'),
            ('Unit/ContentView.swift', 'view.appHaptic(.select, trigger: selectedTab)'),
            ('Unit/Features/Fixture.swift', 'enum AppColor { static let wrong = Color.red }'),
            (DS, 'struct Sibling { let c = Color.red }'),
            (DS, 'struct Sibling { let a = Animation.linear(duration: 1) }'),
            (DS, 'struct Sibling { func tap() { UISelectionFeedbackGenerator().selectionChanged() } }'),
            (DS, 'extension AppColor { static let wrong = Color.blue }'),
            (WIDGET, 'view.foregroundStyle(.red)'),
            (WIDGET, 'view.keylineTint(.secondary)'),
            (WIDGET, 'view.animation(.easeIn(duration: 1), value: value)'),
            (SPLASH, 'view.preferredColorScheme(.dark)'),
            ('Unit/Features/Fixture.swift', 'view.preferredColorScheme(openerVisible ? .dark : .light)'),
        ]
        for file, mutation in cases:
            path = root / file
            path.write_text(fixtures[file] + '\n' + mutation + '\n')
            assert scan(root), f'Guard missed mutation: {file}: {mutation}'
            path.write_text(fixtures[file])
        assert not scan(root), scan(root)
        print(f'guards self-test: PASS (positive fixtures + {len(cases)} rejected mutations)')


if sys.argv[1:] == ['--self-test']:
    self_test()
elif sys.argv[1:]:
    sys.exit('Usage: scripts/check-guards.sh [--self-test]')
else:
    errors = scan(pathlib.Path.cwd())
    if errors:
        print('\n'.join(errors), file=sys.stderr)
        sys.exit(1)
    print('guards: PASS (tracked Unit + UnitWidget Swift; exact token owners)')
PY
