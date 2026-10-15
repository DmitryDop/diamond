import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parent.parent
reports = json.loads((root / 'qa/diamond-hero-scroll-v3-validation.json').read_text())
checks = []
def check(name, result):
    checks.append({'check': name, 'passed': bool(result)})

def central(state):
    return next(layer for layer in state['layers'] if layer['key'] == 'centralRock')

for report in reports:
    width, height = report['width'], report['height']
    initial = report['initial']
    prefix = str(width) + ': '
    check(prefix + 'assets loaded and no horizontal overflow', report['imagesLoaded'] and not report['horizontalOverflow'])
    check(prefix + 'initial composition transforms', all(abs(l['x']) < .001 and abs(l['y']) < .001 and abs(l['scale']-1) < .0001 for l in initial['layers']))
    for name in ['firstPixel', 'early', 'fifteen', 'main', 'full', 'reverse', 'released', 'returned']:
        state = report[name]
        check(prefix + name + ' natural page flow', not state['pin'] and abs(state['hero']['y'] - initial['hero']['y'] + state['scrollY']) < 1 and abs(state['concept']['y'] - state['hero']['bottom']) < 1 and abs(state['hero']['height'] - initial['hero']['height']) < 1)
        if state['stage']['y'] < height and state['stage']['bottom'] > 0:
            progress = 1 - (1-min(1, max(0, state['scrollY']/(height*.55))))**2
            expected = 1 + .1*progress*(1 if width >= 1101 else .4)
            check(prefix + name + ' direct camera progress', abs(central(state)['scale'] - expected) < .0001)
    check(prefix + 'reverse matches forward', abs(central(report['reverse'])['scale']-central(report['fifteen'])['scale']) < .0001)
    check(prefix + 'returned to original pose', all(abs(l['x']) < .001 and abs(l['y']) < .001 and abs(l['scale']-1) < .0001 for l in report['returned']['layers']))
    check(prefix + 'smoke independently animated', report['airBefore']['air'] != report['airAfter']['air'])
    check(prefix + 'reduced motion static', all(l['scale'] == 1 and l['x'] == 0 and l['y'] == 0 for l in report['reduced']['layers']))
    for name in ['cursorLeft', 'cursorRight', 'combined', 'full']:
        state = report[name]
        check(prefix + name + ' cut edges covered', all(l['right'] >= state['stage']['right']-.2 and l['bottom'] >= state['stage']['bottom']-.2 for l in state['layers']))
    if width <= 850:
        check(prefix + 'cursor disabled', report['cursorLeft']['layers'] == report['cursorRight']['layers'])

checkpoint = root / 'qa/checkpoints/2026-10-13-hero-scroll-v3'
old_html = (checkpoint/'index.html').read_text()
new_html = (root/'index.html').read_text()
check('Only HERO wrapper removed from markup', old_html.replace('    <div class="hero-scroll-track" data-hero-track>\n', '').replace('    </div>\n\n    <section class="concept"', '\n    <section class="concept"') == new_html)
old_css = (checkpoint/'styles.css').read_text()
check('Only HERO pin rules removed from CSS', '\n'.join(l for l in old_css.split('\n') if '.hero-scroll-track[data-hero-pin]' not in l) == (root/'css/styles.css').read_text())
old_js = (checkpoint/'main.js').read_text()
new_js = (root/'js/main.js').read_text()
check('Other section logic unchanged', old_js.split('// V2 tuning:')[0] == new_js.split('// V3 tuning:')[0] and old_js.split('if (impactScene &&')[1] == new_js.split('if (impactScene &&')[1])
check('Layer and cursor tuning unchanged', old_js.split('  layers: {')[1].split('\nconst hero =')[0] == new_js.split('  layers: {')[1].split('\nconst hero =')[0])
check('Layer painting and smoke drift unchanged', old_js.split('  const paint = () => {')[1].split('  const draw =')[0] == new_js.split('  const paint = () => {')[1].split('  const draw =')[0])
assets = json.loads((root/'qa/diamond-hero-cinematic-v2-scope-validation.json').read_text())['assetSHA256']
check('All original assets unchanged', all(hashlib.sha256((root/'assets/diamond-hero'/name).read_bytes()).hexdigest() == digest for name, digest in assets.items()))
(root/'qa/diamond-hero-scroll-v3-assertions.json').write_text(json.dumps(checks, indent=2)+'\n')
failed = [c['check'] for c in checks if not c['passed']]
print(json.dumps({'checks': len(checks), 'failed': failed}, indent=2))
raise SystemExit(bool(failed))
