# Printf
Here is an implementation of the C standard library function written in assembly language.
To embed this function to a .cpp file add ```extern "C" int MyPrintf (const char * strng, ...);``` into file.

## Доступные спецификаторы

| Спецификатор | Описание | Пример ввода | Пример вывода |
|-------------|----------|--------------|---------------|
| `%d` | Десятичное целое число (со знаком) | `-12345` | `"-12345"` |
| `%b` | Двоичное представление числа | `5` | `"101"` |
| `%c` | Одиночный символ | `'c'` | `"c"` |
| `%s` | Строка (null-terminated) | `"STRING"` | `"STRING"` |
| `%%` | Вывод символа процента | - | `"%"` |
| `%x` | Шестнадцатеричное число (нижний регистр) | `0xA1B2C3DE` | `"a1b2c3de"` |
| `%o` | Восьмеричное число | `05555` | `"5555"` |

## Примеры использования

```c
MyPrintf("%d", -12345);     // → "-12345"
MyPrintf("%b", 5);          // → "101"
MyPrintf("%c", 'c');        // → "c"
MyPrintf("%s", "STRING");   // → "STRING"
MyPrintf("%%");             // → "%"
MyPrintf("%x", 0xA1B2C3DE); // → "a1b2c3de"
MyPrintf("%o", 05555);      // → "5555"
```
