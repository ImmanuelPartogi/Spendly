import json
import os
import glob
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRANSLATIONS_DIR = os.path.join(ROOT, "assets", "translations")
LIB_DIR = os.path.join(ROOT, "lib")

def check_parity():
    files = sorted(glob.glob(os.path.join(TRANSLATIONS_DIR, "*.json")))
    if not files:
        print("[FAIL] No translation files found.")
        return False

    keys_per_lang = {}
    for f in files:
        lang = os.path.basename(f).replace('.json', '')
        with open(f, 'r', encoding='utf-8') as fp:
            d = json.load(fp)
            keys_per_lang[lang] = set(d.keys())

    all_keys = set()
    for kset in keys_per_lang.values():
        all_keys.update(kset)

    has_error = False
    for lang, kset in keys_per_lang.items():
        missing = all_keys - kset
        if missing:
            print(f"[FAIL] [{lang}.json] Missing {len(missing)} keys: {list(missing)[:5]}")
            has_error = True

    if not has_error:
        print(f"[PASS] Key Parity Check Passed: All {len(keys_per_lang)} languages share {len(all_keys)} identical keys.")
    return not has_error

def check_encoding():
    files = sorted(glob.glob(os.path.join(TRANSLATIONS_DIR, "*.json")))
    mojibake_re = re.compile(r"Ã[ƒâ€Â†«©á­óúñÂ‚â„¢â€š‚]+")
    has_error = False
    for f in files:
        lang = os.path.basename(f).replace('.json', '')
        with open(f, 'r', encoding='utf-8') as fp:
            txt = fp.read()
        matches = mojibake_re.findall(txt)
        if matches:
            print(f"[FAIL] [{lang}.json] Found {len(matches)} mojibake byte corruptions.")
            has_error = True

    if not has_error:
        print("[PASS] Encoding Check Passed: All translation files are clean UTF-8.")
    return not has_error

if __name__ == '__main__':
    print("=== SPENDLY CI LOCALIZATION VALIDATOR ===")
    p_ok = check_parity()
    e_ok = check_encoding()
    if p_ok and e_ok:
        print("[SUCCESS] ALL LOCALIZATION CI CHECKS PASSED!")
    else:
        print("[FAIL] CI LOCALIZATION VALIDATION FAILED!")
        exit(1)
