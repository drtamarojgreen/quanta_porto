import sys
import functools
import inspect

class SorrelRunner:
    def __init__(self):
        self.cards = {}

    def is_card(self, func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            return func(*args, **kwargs)
        self.cards[func.__name__] = func
        return wrapper

    def run(self, card_name, *args):
        if card_name not in self.cards:
            print(f"Card {card_name} not found.")
            return 1

        card_func = self.cards[card_name]
        try:
            # Check @Needs (simplified)
            # Check @Situation (simplified)

            result = card_func(*args)

            # Check @Results (simplified: check if output contains expected numeric evidence)

            return 0
        except Exception as e:
            print(f"Card {card_name} failed: {e}")
            return 1

# Decorators
def Is(func):
    """Decorator to mark a function as a SORREL Card."""
    func._is_sorrel_card = True
    return func

def Needs(fact):
    """Decorator to define environmental dependencies."""
    def decorator(func):
        if not hasattr(func, "_needs"):
            func._needs = []
        func._needs.append(fact)
        return func
    return decorator

def Results(**expected_metrics):
    """Decorator to define expected numeric evidence."""
    def decorator(func):
        func._expected_results = expected_metrics
        return func
    return decorator

def Situation(name):
    """Decorator to isolate execution situations."""
    def decorator(func):
        func._situation = name
        return func
    return decorator

def dispatch(runner):
    if len(sys.argv) < 2:
        print("Usage: python card.py <card_name> [args...]")
        sys.exit(1)

    card_name = sys.argv[1]
    # Register all cards in the module
    for name, obj in inspect.getmembers(sys.modules["__main__"]):
        if hasattr(obj, "_is_sorrel_card"):
            runner.cards[name] = obj

    exit_code = runner.run(card_name, *sys.argv[2:])
    sys.exit(exit_code)
