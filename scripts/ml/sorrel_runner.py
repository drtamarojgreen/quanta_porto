import sys
import functools
import inspect
import os

class FactReader:
    @staticmethod
    def read_facts(filepath):
        facts = {}
        if not os.path.exists(filepath):
            return facts
        with open(filepath, "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or line.startswith("Situation:"):
                    continue
                parts = line.split(" ", 1)
                if len(parts) < 2: continue
                rest = parts[1]
                if "=" in rest:
                    key, val = rest.split("=", 1)
                    facts[key.strip()] = val.strip()
        return facts

class SorrelRunner:
    def __init__(self, facts_file="tests/sdd/facts/ml_testing.facts"):
        self.cards = {}
        self.facts = FactReader.read_facts(facts_file)

    def run(self, card_name, *args):
        if card_name not in self.cards:
            print(f"Card {card_name} not found.")
            return 1

        card_func = self.cards[card_name]

        # 1. Evaluate @Is and @Needs
        is_clause = getattr(card_func, "_is_clause", None)
        if is_clause:
            key, val = is_clause
            if self.facts.get(key) != val:
                print(f"Skip: {card_name} (@Is {key} == {val} not met)")
                return 0 # Standard behavior to return 0 on skipped

        needs_list = getattr(card_func, "_needs", [])
        for need in needs_list:
            if need not in self.facts:
                print(f"Error: {card_name} (@Needs {need} not met)")
                return 1

        try:
            # 2. Execute
            card_func(*args)
            return 0
        except Exception as e:
            print(f"Card {card_name} failed: {e}")
            return 1

def Is(key, value):
    def decorator(func):
        func._is_clause = (key, str(value))
        return func
    return decorator

def Needs(fact):
    def decorator(func):
        if not hasattr(func, "_needs"):
            func._needs = []
        func._needs.append(fact)
        return func
    return decorator

def Results(**kwargs):
    def decorator(func):
        func._results = kwargs
        return func
    return decorator

def Situation(name):
    def decorator(func):
        func._situation = name
        return func
    return decorator

def dispatch(runner):
    if len(sys.argv) < 2:
        print("Usage: python card.py <card_name> [args...]")
        sys.exit(1)

    card_name = sys.argv[1]
    for name, obj in inspect.getmembers(sys.modules["__main__"]):
        if hasattr(obj, "_is_sorrel_card") or hasattr(obj, "_is_clause"):
            runner.cards[name] = obj

    exit_code = runner.run(card_name, *sys.argv[2:])
    sys.exit(exit_code)
