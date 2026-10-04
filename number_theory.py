"""Модуль для перевірки властивостей цілих чисел."""


def is_prime(n):
    """Повертає True, якщо число просте."""
    if not isinstance(n, int) or isinstance(n, bool):
        raise TypeError("Потрібно ввести ціле число")

    if n < 2:
        return False

    divisor = 2
    while divisor * divisor <= n:
        if n % divisor == 0:
            return False
        divisor += 1

    return True


def factorial(n):
    """Обчислює факторіал невід’ємного цілого числа."""
    if not isinstance(n, int) or isinstance(n, bool):
        raise TypeError("Потрібно ввести ціле число")

    if n < 0:
        raise ValueError("Факторіал від’ємного числа не визначений")

    result = 1
    for number in range(2, n + 1):
        result *= number

    return result


def is_even(n):
    """Повертає True, якщо число парне."""
    if not isinstance(n, int) or isinstance(n, bool):
        raise TypeError("Потрібно ввести ціле число")

    return n % 2 == 0


if __name__ == "__main__":
    print("Число 17 просте:", is_prime(17))
    print("Факторіал числа 5:", factorial(5))
    print("Число 8 парне:", is_even(8))
    