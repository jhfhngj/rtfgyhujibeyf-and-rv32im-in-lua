from math import isqrt

print("rtfgyhujibeyfnsdcxzpo interepterer")

stak = [1]
prgm = input("progoroamanamitanika ")
def chardo(char, do):
    global chrr
    if chrr == char:
        return do()
def seti(to):
    global i
    i = to
def none():
    pass
def run(func):
    return func()
def square_root():
    value = stak.pop()
    stak.append(isqrt(value) if value >= 0 else -1)
i = 0
while i<len(prgm):
    chrr = prgm[i]
    try:
        chardo("r",lambda: stak.append(ord(input())))
        chardo("t",lambda: print(chr(stak.pop()),end=""))
        chardo("f",lambda: stak.append(stak.pop()**2))
        chardo("g",square_root)
        chardo("y",lambda: stak.append(stak.pop()*2))
        chardo("h",lambda: stak.append(stak.pop()//2))
        chardo("u",lambda: stak.append(stak.pop()+1))
        chardo("j",lambda: stak.append(stak.pop()-1))
        chardo("i",lambda: stak.append(1))
        chardo("b",lambda: stak.append(-1))
        chardo("e",lambda: stak.append(0))
        chardo("n",lambda: stak.append(stak[-1]))
        chardo("s",lambda: stak.append(stak.pop()+stak.pop()))
        chardo("d",lambda: stak.append(stak.pop()-stak.pop()))
        chardo("c",lambda: seti(stak.pop()-1))
        chardo("x",lambda: seti(i+1) if stak.pop() == 0 else none())
        chardo("z",lambda: stak.append(int(input())))
        chardo("p",none)
        chardo("o",lambda: stak.clear())
    except Exception as e:
        print(stak)
        print(e)
    i += 1