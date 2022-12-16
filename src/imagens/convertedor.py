# -- coding: utf-8 --
import cv2
import numpy as np
import matplotlib.pyplot as plt
from os import listdir, getcwd
from os.path import isfile, join
import PySimpleGUI as sg

# dentro da pasta desse arquivo .py, rode o comando para gerar exe em ./dist/converter.exe
# só copiar e colar
# C:\Python310\python.exe -m PyInstaller --onefile --paths="/usr/lib/python3.10/dist-packages/cv2/python-3.10" .\convertedor.py --exclude-module _bootlocale

layout = [[sg.Text("OBS1: Cyclone 2 só suportará 2 imagens de 60x80 no máximo")],
          [sg.Text("OBS2: Coloque suas imagens numa pasta com esse executável, sendo JPG ou PNG")],
          [sg.Text("OBS3: suas imagens devem estar no modo paisagem, senão sairá com erros ")],
          [sg.Text("Selecione resolução: ")],
          [sg.Combo(["21x28", "24x32", "30x40", "60x80", "120x160", "240x320"], size=(30, 6), default_value="60x80")],
          [sg.Text("Profundidade de bits: (se você não sabe o que está fazendo, deixe assim)")],
          [sg.Combo(["5/6/5", "6/6/6"], size=(30, 6), default_value="6/6/6")],
          [sg.Text("ATENÇÃO: Se por acaso tiver FPGA da marca GOWIN, escolha .MI senão .MIF: ")],
          [sg.Combo([".mif", ".mi"], size=(30, 6), default_value=".mif")],
          [sg.Button("OK")]]
window = sg.Window("Demo", layout)

while True:
    event, values = window.read()
    if event == "OK" or event == sg.WIN_CLOSED:
        break

window.close()

fileslist = [f for f in listdir(getcwd()) if isfile(join(getcwd(), f))]
imagelist = [file for file in fileslist if file[-3:] in ["jpg", "png"]]
tipo = values[2]
profundidade = values[1]

for image in imagelist:
    img = plt.imread(image)
    if img.shape[0] > img.shape[1]:
        img = np.rot90(img)

    dim = list([int(x) for x in values[0].split('x')])
    img = cv2.imread(image)
    img = cv2.rotate(img, cv2.ROTATE_90_CLOCKWISE)
    img_small = cv2.resize(img, dsize=dim, interpolation=cv2.INTER_CUBIC)

    if profundidade == "6/6/6":
        for linha in range(len(img_small)):
            for pixel in range(len(img_small[linha])):
                for cor in range(len(img_small[linha][pixel])):
                    img_small[linha][pixel][cor] = 63 * img_small[linha][pixel][cor] / 255
    else:
        for linha in range(len(img_small)):
            for pixel in range(len(img_small[linha])):
                img_small[linha][pixel][0] = 31 * img_small[linha][pixel][0] / 255
                img_small[linha][pixel][1] = 63 * img_small[linha][pixel][1] / 255
                img_small[linha][pixel][2] = 31 * img_small[linha][pixel][2] / 255

    binR = [a[2:].zfill(6) for a in list(map(bin, img_small[:, :, 2].flatten()))]
    binG = [a[2:].zfill(6) for a in list(map(bin, img_small[:, :, 1].flatten()))]
    binB = [a[2:].zfill(6) for a in list(map(bin, img_small[:, :, 0].flatten()))]

    stringue = "".join("".join(["".join(a) for a in list(zip(binR, binG, binB))]))
    width = 18
    depth = int(int(len(stringue) / 18))
    listmem = [int(stringue[i:i + width], 2) for i in range(0, len(stringue), width)]
    if tipo == ".mif":
        with open(image[:-4] + '.mif', "w") as current_mif:
            current_mif.write(f"WIDTH={width};\n")
            current_mif.write(f"DEPTH={depth};\n")
            current_mif.write("ADDRESS_RADIX=UNS;\n")
            current_mif.write("DATA_RADIX=UNS;\n\n")
            current_mif.write("CONTENT BEGIN\n")
            for idx, palavra in enumerate(listmem):
                current_mif.write("\t" + str(idx) + "\t:\t" + str(palavra) + ";\n")
            # current_mif.write("\t[" + str(len(listmem)) + "..65535]\t:\t0;\n")
            current_mif.write("END;\n")
    elif tipo == ".mi":
        with open(image[:-4] + '.mi', "w") as current_mi:
            current_mi.write(f"#File_format=Bin\n#Address_depth={int(len(stringue) / 18)}\n#Data_width={width}\n")
            for idx, palavra in enumerate(listmem):
                binario = bin(palavra)[2:].zfill(width)
                current_mi.write(binario + "\n")
