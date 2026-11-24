b=open('ddh.cpp','rb').read().split(b'\n')
with open('dump_lines.txt','w',encoding='utf-8') as f:
    for i in range(3358,3400):
        f.write(f'{i+1}: {b[i]!r}\n')
