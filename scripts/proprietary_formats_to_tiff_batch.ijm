/** 
 * Proprietary commercial formats to TIFF Batch Converter
 * 
 * Supported formats:
 *   - ND2 (Nikon)
 *   - LIF (Leica)
 *   - CZI (Zeiss)
 *   - OIR (Evident)
 *   - OIB/OIF (Olympus legacy)
 * 
 * Features:
 *   - Batch conversion with channel/Z/time splitting
 *   - Consistent zero-based naming
 *   - Configurable time series chunking with overlap
 * 
 * 
 */

setBatchMode(true);

// Supported file extensions
SUPPORTED_EXTS = newArray(".nd2", ".lif", ".czi", ".oir", ".oib", ".oif");
OUTPUT_EXT = ".tif";

function isOpen(title) {
    titles = getList("image.titles");
    for (k = 0; k < titles.length; k++) {
        if (titles[k] == title) return true;
    }
    return false;
}

function padIndex(n) {
    if (n < 10) return "00" + n;
    if (n < 100) return "0" + n;
    return "" + n;
}

function isSupportedFormat(fileName) {
    lowerName = toLowerCase(fileName);
    for (i = 0; i < SUPPORTED_EXTS.length; i++) {
        if (endsWith(lowerName, SUPPORTED_EXTS[i])) {
            return true;
        }
    }
    return false;
}

function getInputExtension(fileName) {
    lowerName = toLowerCase(fileName);
    for (i = 0; i < SUPPORTED_EXTS.length; i++) {
        if (endsWith(lowerName, SUPPORTED_EXTS[i])) {
            return SUPPORTED_EXTS[i];
        }
    }
    return "";
}

inputDir = getDirectory("Choose Input Directory (ND2/LIF/CZI/OIR/OIB/OIF files)");
outputDir = getDirectory("Choose Output Directory (TIFF files)");

Dialog.create("Multi-Vendor TIFF Export");
Dialog.addMessage("Supports: ND2 (Nikon), LIF (Leica), CZI (Zeiss), OIR (Evident), OIB/OIF (Olympus)");
Dialog.addCheckbox("Split Channels into separate TIFFs", true);
Dialog.addCheckbox("Split Z-planes into separate TIFFs", false);
Dialog.addCheckbox("Split Time Series into separate TIFFs", false);
Dialog.addNumber("Time frames per split (0 = individual frames)", 0);
Dialog.addNumber("Time overlap between splits (frames)", 0);
Dialog.show();

splitCh = Dialog.getCheckbox();
splitZ = Dialog.getCheckbox();
splitT = Dialog.getCheckbox();
framesPerSplit = Dialog.getNumber();
timeOverlap = Dialog.getNumber();

fileList = getFileList(inputDir);
processedCount = 0;

for (i = 0; i < fileList.length; i++) {
    if (!isSupportedFormat(fileList[i])) continue;
    
    filePath = inputDir + fileList[i];
    inputExt = getInputExtension(fileList[i]);
    
    // Open as hyperstack
    run("Bio-Formats Importer", 
        "open=[" + filePath + "] autoscale color_mode=Composite view=Hyperstack stack_order=XYCZT display:False");
    
    originalTitle = getTitle();
    getDimensions(width, height, channels, slices, frames);
    
    print("Processing: " + fileList[i] + " (C:" + channels + ", Z:" + slices + ", T:" + frames + ")");
    
    // Handle time series splitting
    if (splitT && frames > 1) {
        processTimeSeriesSplitting(originalTitle, fileList[i], inputExt, outputDir, splitCh, splitZ, channels, slices, frames, framesPerSplit, timeOverlap);
    } else if (splitCh && channels > 1) {
        processChannelSplitting(originalTitle, fileList[i], inputExt, outputDir, splitZ, channels, slices, frames);
    } else if (splitZ && slices > 1) {
        processZSplitting(originalTitle, fileList[i], inputExt, outputDir, slices);
    } else {
        // Save as single file
        saveName = replace(fileList[i], inputExt, OUTPUT_EXT);
        savePath = outputDir + saveName;
        print("Saving: " + savePath);
        run("Tiff...", "save=[" + savePath + "]");
        close();
    }
    
    // Clean up any remaining windows
    cleanupWindows(fileList[i]);
    processedCount++;
}

print("Conversion complete: " + processedCount + " files processed.");
setBatchMode(false);

function processTimeSeriesSplitting(originalTitle, fileName, inputExt, outputDir, splitCh, splitZ, channels, slices, frames, framesPerSplit, timeOverlap) {
    selectWindow(originalTitle);
    
    if (framesPerSplit == 0) {
        // Split into individual time frames
        for (t = 1; t <= frames; t++) {
            selectWindow(originalTitle);
            run("Make Substack...", "frames=" + t);
            timeTitle = getTitle();
            
            if (splitCh && channels > 1) {
                processChannelSplittingForTime(timeTitle, fileName, inputExt, outputDir, splitZ, channels, slices, t - 1);
            } else if (splitZ && slices > 1) {
                processZSplittingForTime(timeTitle, fileName, inputExt, outputDir, slices, t - 1);
            } else {
                saveName = replace(fileName, inputExt, "_T" + padIndex(t - 1) + OUTPUT_EXT);
                savePath = outputDir + saveName;
                print("Saving: " + savePath);
                run("Tiff...", "save=[" + savePath + "]");
                close();
            }
        }
    } else {
        // Split into chunks of specified size
        step = framesPerSplit - timeOverlap;
        if (step <= 0) step = 1; // Prevent infinite loop
        
        splitIndex = 0;
        for (startFrame = 1; startFrame <= frames; startFrame += step) {
            endFrame = Math.min(startFrame + framesPerSplit - 1, frames);
            
            selectWindow(originalTitle);
            frameRange = "";
            for (f = startFrame; f <= endFrame; f++) {
                if (frameRange != "") frameRange += ",";
                frameRange += f;
            }
            
            run("Make Substack...", "frames=" + frameRange);
            timeTitle = getTitle();
            
            if (splitCh && channels > 1) {
                processChannelSplittingForTimeChunk(timeTitle, fileName, inputExt, outputDir, splitZ, channels, slices, splitIndex, startFrame - 1, endFrame - 1);
            } else if (splitZ && slices > 1) {
                processZSplittingForTimeChunk(timeTitle, fileName, inputExt, outputDir, slices, splitIndex, startFrame - 1, endFrame - 1);
            } else {
                saveName = replace(fileName, inputExt, "_T" + padIndex(startFrame - 1) + "-" + padIndex(endFrame - 1) + OUTPUT_EXT);
                savePath = outputDir + saveName;
                print("Saving: " + savePath);
                run("Tiff...", "save=[" + savePath + "]");
                close();
            }
            
            splitIndex++;
            if (endFrame >= frames) break;
        }
    }
    
    // Close original
    if (isOpen(originalTitle)) {
        selectWindow(originalTitle);
        close();
    }
}

function processChannelSplittingForTime(timeTitle, fileName, inputExt, outputDir, splitZ, channels, slices, timeIndex) {
    selectWindow(timeTitle);
    run("Split Channels");
    wait(500);
    
    // Get split channel titles
    splitTitles = newArray(channels);
    allTitles = getList("image.titles");
    idx = 0;
    for (j = 0; j < allTitles.length; j++) {
        if (indexOf(allTitles[j], timeTitle) != -1 && idx < channels) {
            splitTitles[idx] = allTitles[j];
            idx++;
        }
    }
    
    for (j = 0; j < splitTitles.length; j++) {
        selectWindow(splitTitles[j]);
        if (splitZ && slices > 1) {
            for (z = 1; z <= slices; z++) {
                run("Make Substack...", "slices=" + z);
                saveName = replace(fileName, inputExt, "_C" + padIndex(j) + "_Z" + padIndex(z - 1) + "_T" + padIndex(timeIndex) + OUTPUT_EXT);
                savePath = outputDir + saveName;
                print("Saving: " + savePath);
                run("Tiff...", "save=[" + savePath + "]");
                close();
            }
        } else {
            saveName = replace(fileName, inputExt, "_C" + padIndex(j) + "_T" + padIndex(timeIndex) + OUTPUT_EXT);
            savePath = outputDir + saveName;
            print("Saving: " + savePath);
            run("Tiff...", "save=[" + savePath + "]");
        }
        close();
    }
    
    // Close time substack if still open
    if (isOpen(timeTitle)) {
        selectWindow(timeTitle);
        close();
    }
}

function processChannelSplittingForTimeChunk(timeTitle, fileName, inputExt, outputDir, splitZ, channels, slices, chunkIndex, startTime, endTime) {
    selectWindow(timeTitle);
    run("Split Channels");
    wait(500);
    
    // Get split channel titles
    splitTitles = newArray(channels);
    allTitles = getList("image.titles");
    idx = 0;
    for (j = 0; j < allTitles.length; j++) {
        if (indexOf(allTitles[j], timeTitle) != -1 && idx < channels) {
            splitTitles[idx] = allTitles[j];
            idx++;
        }
    }
    
    for (j = 0; j < splitTitles.length; j++) {
        selectWindow(splitTitles[j]);
        if (splitZ && slices > 1) {
            for (z = 1; z <= slices; z++) {
                run("Make Substack...", "slices=" + z);
                saveName = replace(fileName, inputExt, "_C" + padIndex(j) + "_Z" + padIndex(z - 1) + "_T" + padIndex(startTime) + "-" + padIndex(endTime) + OUTPUT_EXT);
                savePath = outputDir + saveName;
                print("Saving: " + savePath);
                run("Tiff...", "save=[" + savePath + "]");
                close();
            }
        } else {
            saveName = replace(fileName, inputExt, "_C" + padIndex(j) + "_T" + padIndex(startTime) + "-" + padIndex(endTime) + OUTPUT_EXT);
            savePath = outputDir + saveName;
            print("Saving: " + savePath);
            run("Tiff...", "save=[" + savePath + "]");
        }
        close();
    }
    
    // Close time substack if still open
    if (isOpen(timeTitle)) {
        selectWindow(timeTitle);
        close();
    }
}

function processZSplittingForTime(timeTitle, fileName, inputExt, outputDir, slices, timeIndex) {
    selectWindow(timeTitle);
    for (z = 1; z <= slices; z++) {
        run("Make Substack...", "slices=" + z);
        saveName = replace(fileName, inputExt, "_Z" + padIndex(z - 1) + "_T" + padIndex(timeIndex) + OUTPUT_EXT);
        savePath = outputDir + saveName;
        print("Saving: " + savePath);
        run("Tiff...", "save=[" + savePath + "]");
        close();
    }
    
    if (isOpen(timeTitle)) {
        selectWindow(timeTitle);
        close();
    }
}

function processZSplittingForTimeChunk(timeTitle, fileName, inputExt, outputDir, slices, chunkIndex, startTime, endTime) {
    selectWindow(timeTitle);
    for (z = 1; z <= slices; z++) {
        run("Make Substack...", "slices=" + z);
        saveName = replace(fileName, inputExt, "_Z" + padIndex(z - 1) + "_T" + padIndex(startTime) + "-" + padIndex(endTime) + OUTPUT_EXT);
        savePath = outputDir + saveName;
        print("Saving: " + savePath);
        run("Tiff...", "save=[" + savePath + "]");
        close();
    }
    
    if (isOpen(timeTitle)) {
        selectWindow(timeTitle);
        close();
    }
}

function processChannelSplitting(originalTitle, fileName, inputExt, outputDir, splitZ, channels, slices, frames) {
    selectWindow(originalTitle);
    run("Split Channels");
    wait(500);
    
    // Capture channel window titles immediately after split
    splitTitles = newArray(channels);
    allTitles = getList("image.titles");
    idx = 0;
    for (j = 0; j < allTitles.length; j++) {
        if (indexOf(allTitles[j], originalTitle) != -1 && idx < channels) {
            splitTitles[idx] = allTitles[j];
            idx++;
        }
    }
    
    // Now loop through the captured titles
    for (j = 0; j < splitTitles.length; j++) {
        selectWindow(splitTitles[j]);
        if (splitZ && slices > 1) {
            for (z = 1; z <= slices; z++) {
                run("Make Substack...", "slices=" + z);
                saveName = replace(fileName, inputExt, "_C" + padIndex(j) + "_Z" + padIndex(z - 1) + OUTPUT_EXT);
                savePath = outputDir + saveName;
                print("Saving: " + savePath);
                run("Tiff...", "save=[" + savePath + "]");
                close();
            }
        } else {
            saveName = replace(fileName, inputExt, "_C" + padIndex(j) + OUTPUT_EXT);
            savePath = outputDir + saveName;
            print("Saving: " + savePath);
            run("Tiff...", "save=[" + savePath + "]");
            close();
        }
    }
    
    // Close original if still open
    if (isOpen(originalTitle)) {
        selectWindow(originalTitle);
        close();
    }
}

function processZSplitting(originalTitle, fileName, inputExt, outputDir, slices) {
    selectWindow(originalTitle);
    for (z = 1; z <= slices; z++) {
        run("Make Substack...", "slices=" + z);
        saveName = replace(fileName, inputExt, "_Z" + padIndex(z - 1) + OUTPUT_EXT);
        savePath = outputDir + saveName;
        print("Saving: " + savePath);
        run("Tiff...", "save=[" + savePath + "]");
        close();
    }
    
    if (isOpen(originalTitle)) {
        selectWindow(originalTitle);
        close();
    }
}

function cleanupWindows(fileName) {
    openWindows = getList("image.titles");
    for (w = 0; w < openWindows.length; w++) {
        if (indexOf(openWindows[w], fileName) != -1) {
            selectWindow(openWindows[w]);
            close();
        }
    }
}