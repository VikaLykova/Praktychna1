"""Автоматичні тести для модуля number_theory.py."""

import pytest
from number_theory import is_prime, factorial, is_even


def test_is_prime():
    assert is_prime(2) is True
    assert is_prime(17) is True
    assert is_prime(9) is False
    assert is_prime(25) is False
    assert is_prime(1) is False
    assert is_prime(0) is False
    assert is_prime(-7) is False


def test_factorial():
    assert factorial(0) == 1
    assert factorial(1) == 1
    assert factorial(5) == 120
    assert factorial(7) == 5040


def test_factorial_negative():
    """Перевіряємо помилку для від’ємного числа."""
    with pytest.raises(ValueError):
        factorial(-3)


def test_is_even():
    assert is_even(8) is True
    assert is_even(7) is False
    assert is_even(0) is True
    assert is_even(-4) is True
    assert is_even(-3) is False


def test_invalid_types():
    """Функції мають відхиляти нецілі числа та інші типи."""
    for function in (is_prime, factorial, is_even):
        for value in (2.5, "5", None, True):
            with pytest.raises(TypeError):
                function(value)
                