preferences.rulerUnits = Units.POINTS;

var SIZE_IOS = [1024, 512, 152, 144, 120, 114, 100, 80, 76, 72, 58, 57, 50, 40, 29];
var SIZE_AND = [["xxh", 144], ["xh", 96], ["h", 72], ["m", 48], ["l", 32]];

var dst = activeDocument.path + "/";
activeDocument.duplicate();
for (var i = 0; i < SIZE_IOS.length; i++) {
    save(SIZE_IOS[i], "Icon-" + SIZE_IOS[i]);
}
activeDocument.close(SaveOptions.DONOTSAVECHANGES);
activeDocument.duplicate();
for (var i = 0; i < SIZE_AND.length; i++) {
    var e = SIZE_AND[i];
    var dir = new Folder(dst + "drawable-" + e[0] + "dpi");
    if (!dir.exists) dir.create();
    save(e[1], dir.name + "/icon");
}
activeDocument.close(SaveOptions.DONOTSAVECHANGES);

function save(size, name) {
    activeDocument.resizeImage(size, size);
    var fileObj = new File(dst + name + ".png");
    pngOpt = new PNGSaveOptions();
    pngOpt.interlaced = false;
    activeDocument.saveAs(fileObj, pngOpt, true, Extension.LOWERCASE);
}
