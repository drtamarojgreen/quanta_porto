import sys
import functools
import inspect
import os
import json

class FactManager:
    """Handles loading, saving, and validating SORREL facts."""
    def __init__(self, base_path="tests/sdd/facts"):
        self.base_path = base_path

    def get_fact_path(self, situation, fact_name):
        return os.path.join(self.base_path, situation, f"{fact_name}.fact")

    def save_fact(self, situation, fact_name, value):
        path = self.get_fact_path(situation, fact_name)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(str(value))
        print(f"Fact recorded: {path} = {value}")

    def load_fact(self, situation, fact_name):
        path = self.get_fact_path(situation, fact_name)
        if not os.path.exists(path):
            return None
        with open(path, "r") as f:
            return f.read().strip()

    def check_needs(self, situation, needs):
        for need in needs:
            if self.load_fact(situation, need) is None:
                print(f"Missing dependency: Fact '{need}' in situation '{situation}'")
                return False
        return True

class SorrelRunner:
    def __init__(self):
        self.cards = {}
        self.fact_manager = FactManager()

    def run(self, card_name, *args):
        if card_name not in self.cards:
            print(f"Card {card_name} not found.")
            return 1

        card_func = self.cards[card_name]
        situation = getattr(card_func, "_situation", "Default")
        needs = getattr(card_func, "_needs", [])

        # 1. Fact Discovery & Need Validation
        if not self.fact_manager.check_needs(situation, needs):
            return 1

        try:
            # 2. Execution & Observation
            result_map = card_func(*args)

            # 3. Fact Recording
            expected = getattr(card_func, "_expected_results", {})
            if result_map:
                for key, val in result_map.items():
                    self.fact_manager.save_fact(situation, key, val)

            return 0
        except Exception as e:
            print(f"Card {card_name} failed: {e}")
            return 1

# Decorators
def Is(func):
    func._is_sorrel_card = True
    return func

def Needs(fact):
    def decorator(func):
        if not hasattr(func, "_needs"):
            func._needs = []
        func._needs.append(fact)
        return func
    return decorator

def Results(**expected_metrics):
    def decorator(func):
        func._expected_results = expected_metrics
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
        if hasattr(obj, "_is_sorrel_card"):
            runner.cards[name] = obj

    exit_code = runner.run(card_name, *sys.argv[2:])
    sys.exit(exit_code)
