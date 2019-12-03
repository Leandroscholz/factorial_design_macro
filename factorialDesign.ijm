/* 
 *  The intention of this macro is to test combinations of image enhancement methods
 *  Design #1
 *  Factors: (-1 / +1)
 *  	1- Image Deconvolution with estimated PSF
 			Levels: Do not use / Yes, use (RLTV, 200 iterations lambda 0.01)
 *		2- Background subtraction 
 *			Levels: Do not use / Yes, use (10 rolling ball radius) 
 *		3- Image Normalization 
 *			Levels: Do not use / Yes, use (0.4% saturated px)
 *		4- Vessel enhancement method Frangi 
 *			Levels: Do not use / Yes, use (5 scales, diameter from 2 to 5px) 
 *		5- Median filter
 *			Levels: Do not use / Yes, use (3px) 
 *	
 *	5 Factors, 2 Levels for each factor
 *	2^5 = 32 result images
*/
// Do not show image windows
//setBatchMode('true');
//setBatchMode("Hide");
/*_______________________________________________________________________________
IMPORTANT PIECE OF INFORMATION

The directory in which the macro will run must have the raw images to be 
processed and the factorial design table as a .txt file with tab divided columns

The factorial design table looks like this, where the rows are the 'tests' or 
'experiments', the columns are the factors and the the value in each element of
the matrix are the levels. (instead of -1 / +1 ,  0 / 1 was used)

0	0	0	
1	0	0
0	1	0	
1	1	0	
0	0	1	
1	0	1	
0	1	1	
1	1	1	

*/
//_______________________________________________________________________________
// INPUTS 
//directory where the results will be saved
dir=getDirectory("");
print(dir);

//path to the psf file to be used during the deconvolution operation
psfpath="G:\\PP_TestFinal\\PSFGL3_32bitfloat_confocal.tif";
print(psfpath);

//name of the 2 first files - best and worst quality
filenames=newArray("1_Raw");
nFiles=filenames.length;

// file format suffix
format=".tif";			       

// Define number of factors, number of levels and number of final images 
nFactors=5;
nLevels=2;
totalImages=(pow(nLevels,nFactors));


//_______________________________________________________________________________

// Save all the result images based on the size of the factorial design
for(i=0;i<nFiles;i++){
	open(dir+filenames[i]+format);
    rawID=getImageID();
	print("on the loop to save the images");
	for(test=0;test<totalImages;test++){
		saveAs("Tiff", dir+filenames[i]+"_"+(test+1)+format);
		print("saved image: "+(i+1)+" test #"+(test+1));
	}
	close(rawID);
}

run("Close All");
print("ended file-saving loop");

//_______________________________________________________________________________

// get factorial design file "factorial.txt" and load as a text image
run("Text Image... ", "open=G:\\PP_TestFinal\\factorial.txt");
factorialtable=getImageID();

for(i=0;i<nFiles;i++){ 
	// runs a loop to perform operations from factor 1 trough nFactors 
	for(factor=1;factor<=nFactors;factor++){

		/* the macro is going to run the operation only nNewImages times. 
		 *  (in our factorial design we only run operations on +1 level and 
		 *  on level -1 we just save the image without doing any operations)
		 *  For example, when running the first factor it will run 2^1 times.
		 *	followed by 2^2= 4 times. This is done to save time.
		 */
		nNewImages=pow(2,factor);
		
		for(j=1;j<=nNewImages;j++){
			selectImage(factorialtable);
			
			if(getPixel(factor-1,j-1)==0){
				// do nothing, the -1 level of all factors mean doing nothing.
				print("Did nothing to test image "+j+" since its factor "+factor+" is -1");
			}
			if(getPixel(factor-1,j-1)==1){
				if(factor==1){
					
					// run operation of factor 1 level +1
					image="-image file "+dir+filenames[i]+"_"+j+format;
					psf=" -psf file "+psfpath;
					algorithm=" -algorithm TM 200 1,0000 0,0100";
					parameters=" -verbose prolix -constraint nonnegativity -fft JTransforms -epsilon 1E-8";
					run("DeconvolutionLab2 Launch", image + psf + algorithm + parameters);
					print("Executed deconvolution to image "+j+" since its factor "+factor+" is +1");

    				while (!isOpen("Final Display of TM")) {
   						wait(100);
					}
					// code below this line will only run once there is a "myStackName" image open
					print("The deconvolution process has been finished");
					selectWindow("Final Display of TM");
					deconvolvedID=getImageID();
					selectImage(deconvolvedID);
					run("8-bit");
					
					// order the slices properly (for some reason the deconvolution algorithm changes the order of the original stack
					run("Slice Keeper", "first=1 last=25 increment=1");
					rename("IMG2");
					selectImage(deconvolvedID);
					run("Slice Keeper", "first=26 last=76 increment=1");
					rename("IMG1");
					run("Concatenate...", "  image1=[IMG1] image2=[IMG2] image3=[-- None --]");
					concatImg=getImageID();
					//save image
					selectImage(concatImg);
					saveAs("Tiff",dir+filenames[i]+"_"+(j)+format);

					// save remaining images with the altered images 
					step=pow(2,factor);
					for(k=j+step;k<=(totalImages);k=k+step){
						print("saved test image "+k+" with the same results as "+j);
						selectImage(concatImg);
						saveAs("Tiff",dir+filenames[i]+"_"+(k)+format);
					}
					close(deconvolvedID);
					close(concatImg);
					runMacro("G:\\PP_TestFinal\\Closeallwindows.ijm");
				}
				if(factor==2){
					open(dir+filenames[i]+"_"+j+format);
					openImg=getImageID();
					// run operation of factor 2 level +1
					run("Subtract Background...", "rolling=10 stack");
					
					print("Executed background subtraction to image "+j+" since its factor "+factor+" is +1");
					//save image
					saveAs("Tiff",dir+filenames[i]+"_"+(j)+format);
					
					// save remaining images with the altered images
					step=pow(2,factor);
					for(k=j+step;k<=(totalImages);k=k+step){
							print("saved test image "+k+" with the same results as "+j);
							saveAs("Tiff",dir+filenames[i]+"_"+(k)+format);
						}
					close(openImg);
					runMacro("G:\\PP_TestFinal\\Closeallwindows.ijm");
				}
				if(factor==3){
					open(dir+filenames[i]+"_"+j+format);
					openImg=getImageID();
					// run operation of factor 3 level +1
					run("Enhance Contrast...", "saturated=0.4 normalize process_all");
					
					print("Executed contrast enhancement (normalization) to image "+j+" since its factor "+factor+" is +1");
					//save image
					saveAs("Tiff",dir+filenames[i]+"_"+(j)+format);

					// save remaining images with the altered images 
					step=pow(2,factor);
					for(k=j+step;k<=(totalImages);k=k+step){
							print("saved test image "+k+" with the same results as "+j);
							saveAs("Tiff",dir+filenames[i]+"_"+(k)+format);
					}
					close(openImg);
					runMacro("G:\\PP_TestFinal\\Closeallwindows.ijm");
				}
				if(factor==4){
					open(dir+filenames[i]+"_"+j+format);
					openImg=getImageID();
					// run operation of factor 4 level +1
	
					run("Frangi Vesselness (imglib, experimental)", "number=5 minimum=2 maximum=5");
					frangiID=getImageID();
					selectImage(frangiID);
					run("8-bit");

					print("Executed Frangi vessel enhancement to image "+j+" since its factor "+factor+" is +1");
					//save image
					saveAs("Tiff",dir+filenames[i]+"_"+(j)+format);

					// save remaining images with the altered images 
					step=pow(2,factor);
					for(k=j+step;k<=(totalImages);k=k+step){
							print("saved test image "+k+" with the same results as "+j);
							saveAs("Tiff",dir+filenames[i]+"_"+(k)+format);
					}
					close(openImg);
					close(frangiID);
					runMacro("G:\\PP_TestFinal\\Closeallwindows.ijm");
				}
				if(factor==5){
					open(dir+filenames[i]+"_"+j+format);
					openImg=getImageID();
					// run operation of factor 5 level +1
					run("Median...", "radius=3 stack");

					print("Executed smoothing with median filter to image "+j+" since its factor "+factor+" is +1");
					//save image
					saveAs("Tiff",dir+filenames[i]+"_"+(j)+format);					
					close(openImg);
					runMacro("G:\\PP_TestFinal\\Closeallwindows.ijm");
				}
			}

		}
	}
}
 