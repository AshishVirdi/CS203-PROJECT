`define Y_SIZE 2048     //maximum size of y dots/pixels
`define X_SIZE 2048     //maximum size of x dots/pixels
`define HIGH   255      //maximum value of a pixel
`define LOW      0      //minimum value of a pixel

module Img_prcs;
parameter read_filename="FLAG.bmp";//input file name
parameter write_filename1="Images/Original.bmp";//output file just after read
parameter write_filename2="Images/BnW.bmp";//ouput file, Black and White with strength
parameter write_filename3="Images/BinaryBnW.bmp";//output file Black and White with binary
parameter write_filename4="Images/Inverted.bmp";// inveted image
parameter write_filename5="Images/Bright.bmp";// Brightened image
parameter write_filename6="Images/Redfltr.bmp";// Redfilter image
parameter write_filename7="Images/Greenfltr.bmp";// Greenfilter image
parameter write_filename8="Images/Bluefltr.bmp";// Bluefilter image
parameter write_filename9="Images/RnGfltr.bmp";// only red and green                                   
parameter write_filename10="Images/RnBfltr.bmp";// only red and blue
parameter write_filename11="Images/Pinkfltr.bmp";// apply pink filter to boxes where R>100;

parameter write_filename12="Images/edge.bmp";// edge detection 
parameter write_filename13="Images/Imgsmooth.bmp";// image smoothening 
parameter write_filename14="Images/Imgsharpen.bmp";// image Sharpening
parameter write_filename15="Images/meadian.bmp";// median filter
/* ****** EXTRA FILTERS MAY BE ADDED IF NEEDED ****** */

// parameter write_filename14="14.bmp";// image smoothening 
// parameter write_filename15="15.bmp";// image smoothening 
// parameter write_filename16="16.bmp";// image smoothening 
// parameter write_filename17="17.bmp";// image smoothening 
// parameter write_filename18="18.bmp";// image smoothening 
parameter [7:0] INTENSITY=10;


//*****  VARIABLES FOR READING AND WRITING BMP HEADER ********// 
reg [0:31] biCompression, biSizeImage, biXPelsPerMeter, biYPelsPerMeter, biClrUsed, biClrImportant;
reg [0:15] bfType;
reg [0:15] bfReserved1, bfReserved2;
reg [0:31] bfOffBits, bfSize ,biSize, biWidth, biHeight ,temp32;
reg [0:15] biPlanes;
reg [0:15] biBitCount , temp16;
reg [7:0] image_in [0:`Y_SIZE][0:`X_SIZE][0:2]; //input color matrix
reg [7:0] image_out [0:`Y_SIZE][0:`X_SIZE][0:2]; //output color matrix
reg [7:0] image_bw [0:`Y_SIZE][0:`X_SIZE], temp8; //shade matrix

/***********************************************************/
// FUNCTIONS FOR REVERSING 8,16 AND 32 BIT REGISTERS //
function [7:0] rev_8b (input [7:0] data);
integer i;
begin
    for (i=0; i < 8; i=i+1) begin : reverse
        rev_8b[7-i] = data[i]; 
    end
end
endfunction

function [15:0] rev_16b (input [15:0] data);
integer i;
begin
    for (i=0; i < 16; i=i+1) begin : reverse
        rev_16b[15-i] = data[i]; 
    end
end
endfunction

function [31:0] rev_32b (input [31:0] data);
integer i;
begin
    for (i=0; i < 32; i=i+1) begin : reverse
        rev_32b[31-i] = data[i]; 
    end
end
endfunction
/***********************************************************/

/***********************************************************/
// Read 24Bit bitmap file 
task readBMP(input [128*8:1] read_filename);
        integer fp;
        integer x;
        integer  i, j, k;
        reg [7:0] byte;
        begin   
                // Open File
                fp = $fopen(read_filename, "rb");//must be binary read mode
                if (!fp) begin
                        $display("readBmp: Open error!\n");
                        $finish;
                end
                $display("input file : %s\n", read_filename);
                // Read Header Informations
                x = $fread(temp16,  fp);
                bfType =  rev_16b(temp16);
                $display("%d : %b\n", x, bfType);
                x = $fread(temp32,  fp);
                bfSize =  rev_32b(temp32);
                $display("%d : %b\n", x, bfSize);
                x = $fread(temp16, fp);
                bfReserved1 =  rev_16b(temp16);
                $display("%d : %b\n", x, bfReserved1);
                x = $fread(temp16, fp);
                bfReserved2 =  rev_16b(temp16);
                $display("%d : %b\n", x, bfReserved2);
                x = $fread(temp32,fp);
                bfOffBits =  rev_32b(temp32);
                $display("%d : %b\n", x, bfOffBits);
                x = $fread(temp32,fp);
                biSize =  rev_32b(temp32);
                $display("%d : %b\n", x, biSize); 
                x = $fread(temp32, fp);
                biWidth =  rev_32b(temp32);
                $display("%d : %b\n", x, biWidth);
                //  if (biWidth%4) begin
                //          $display("Sorry, biWidth%4 must be zero in this program. Found =%d",biWidth);
                //         $finish;
                //  end
                x = $fread(temp32, fp);
                biHeight =  rev_32b(temp32);
                $display("%d : %b\n", x, biHeight);
                x = $fread(temp16, fp);
                biPlanes =  rev_16b(temp16);
                $display("%d : %b\n", x, biPlanes);
                x = $fread(temp16,  fp);
                biBitCount =  rev_16b(temp16);
                $display("%d : %b\n", x, biBitCount);
                if (biBitCount !=24) begin
                        $display("Sorry, biBitCount must be 24 in this program. Found=%d",biBitCount);
                        $finish;
                end
                x = $fread(temp32,fp);
                biCompression = rev_32b(temp32);
                $display("%d : %b\n", x, biCompression);
                x = $fread(temp32,fp);
                biSizeImage =  rev_32b(temp32);
                $display("%d : %b\n", x, biSizeImage);
                x = $fread(temp32, fp);
                biXPelsPerMeter =  rev_32b(temp32);
                $display("%d : %b\n", x, biXPelsPerMeter);
                x = $fread(temp32, fp);
                 biYPelsPerMeter =  rev_32b(temp32);
                $display("%d : %b\n", x, biYPelsPerMeter);
                x = $fread(temp32,  fp);
                biClrUsed =  rev_32b(temp32);
                $display("%d : %b\n", x, biClrUsed);
                x = $fread(temp32, fp);
                biClrImportant =  rev_32b(temp32);
                $display("%d : %b\n", x, biClrImportant);
                
                $display("%d\n",biHeight*biWidth*3);
             
        // Read RGB Data
                for (i=0; i<  biHeight*4; i=i+1) 
                begin
                        for (j=0; j<  biWidth; j=j+1)
                         begin
                                for (k=0; k<3; k=k+1)
                                 begin
                                        x = $fread(temp8,fp);
                                        byte = rev_8b(temp8);
                                        image_in[biHeight*4-i][j][2-k]=byte;
                                 end
                        end    
                end
                $display("%d  %d %d %d",i,biHeight, j , biWidth);
                $display("Current POS=%d",$ftell(fp));
                $fclose(fp);
        end
endtask
/***********************************************************/


/***********************************************************/
//Output 24bits to bitmap file
task writeBMP(input [128*8:1] write_filename,input signal);
        integer fp;
        integer  i, j, k;
        begin
        // Open File
                fp = $fopen(write_filename, "wb");//must be binary read mode
                if (!fp) begin
                        $display("writeBmp: Open error!\n");
                        $finish;
                end
                $display("output file : %s\n", write_filename);
                $display("Current WPOS=%d",$ftell(fp));
        // Write Header Informations 
                temp16 =  rev_16b(bfType);
                $fwrite(fp,"%c%c",temp16[0:7],temp16[8:15]);
                $display("%c%c",temp16[0:7],temp16[8:15]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(bfSize);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp16 =  rev_16b(bfReserved1);
                $fwrite(fp,"%c%c",temp16[0:7],temp16[8:15]);
                $display("%c%c",temp16[0:7],temp16[8:15]);
                $display("Current WPOS=%d",$ftell(fp));

                temp16 =  rev_16b(bfReserved2);
                $fwrite(fp,"%c%c",temp16[0:7],temp16[8:15]);
                $display("%c%c",temp16[0:7],temp16[8:15]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(bfOffBits);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));

                temp32 =  rev_32b(biSize);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biWidth);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biHeight);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp16 =  rev_16b(biPlanes);
                $fwrite(fp,"%c%c",temp16[0:7],temp16[8:15]);
                $display("%c%c",temp16[0:7],temp16[8:15]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp16 =  rev_16b(biBitCount);
                $fwrite(fp,"%c%c",temp16[0:7],temp16[8:15]);
                $display("%c%c",temp16[0:7],temp16[8:15]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biCompression);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biSizeImage);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biXPelsPerMeter);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biYPelsPerMeter);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biClrUsed);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("Current WPOS=%d",$ftell(fp));
                
                temp32 =  rev_32b(biClrImportant);
                $fwrite(fp,"%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
                $display("%c%c%c%c",temp32[0:7],temp32[8:15],temp32[16:23],temp32[24:31]);
 
                $display("Current WPOS=%d",$ftell(fp));
                $display("%d\n",biHeight*biWidth*3);
        // Write Bitmap Data
                for (i=0; i< biHeight*4; i=i+1) begin
                        for (j=0; j< biWidth; j=j+1) begin
                                for (k=0; k<3; k=k+1)  begin
                                        if (signal) begin
                                           temp8 = rev_8b(image_out[biHeight*4-i][j][2-k]);
                                           $fwrite(fp,"%c",temp8);
                                        end   
                                        else begin 
                                           temp8 = rev_8b(image_in[biHeight*4-i][j][2-k]);
                                           $fwrite(fp,"%c",temp8);
                                        end
                                end
                        end
                end
                $display("Current WPOS=%d",$ftell(fp));
                $fclose(fp);
        end
endtask
/***********************************************************/


/***********************************************************/
//Convert RGB to 256 levels of Black & White
task BMPto256BW;
        integer y, x, a;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin
                                a =$rtoi(0.3*image_in[y][x][0] + 0.59*image_in[y][x][1] + 0.11*image_in[y][x][2]);
                                if (a<`LOW) a = `LOW;
                                if (a>`HIGH) a = `HIGH;
                                image_bw[y][x] = a;
                        end
                end
        end
endtask
/***********************************************************/



/***********************************************************/
// Invert BMP image 
task invertBMP;
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin
                                b =$rtoi(0.3*image_in[y][x][0] + 0.59*image_in[y][x][1] + 0.11*image_in[y][x][2]);
                                c =$rtoi(0.3*image_in[y][x][0] + 0.59*image_in[y][x][1] + 0.11*image_in[y][x][2]);
                                a = (b+c)/2; 
                                image_out[y][x][0] = 255-a;
                                image_out[y][x][1] = 255-a;
                                image_out[y][x][2] = 255-a;
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// Grayscale BMP image
task brightnessBMP(input [7:0]value,input [0:0]sign);
        integer y, x, a,b,c;
        if (sign) begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                a = image_in[y][x][0] + value;
                                if (a>255)
                                   image_out[y][x][0] = 255;
                                else
                                   image_out[y][x][0] = a;
                                b = image_in[y][x][1] + value;
                                if (b>255)
                                   image_out[y][x][1] = 255;
                                else
                                   image_out[y][x][1] = b;
                                c = image_in[y][x][2] + value;
                                if (c>255)
                                   image_out[y][x][2] = 255;
                                else
                                   image_out[y][x][2] = c;
                        end
                end
        end
            
        else begin
             for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                a = image_in[y][x][0] - value;
                                if (a[8]==1)
                                   image_out[y][x][0] = 0;
                                else
                                   image_out[y][x][0] = a;
                                b = image_in[y][x][1] - value;
                                if (b[8]==1)
                                   image_out[y][x][1] = 0;
                                else
                                   image_out[y][x][1] = b;
                                c = image_in[y][x][2] - value;
                                if (c[8]==1)
                                   image_out[y][x][2] = 0;
                                else
                                   image_out[y][x][2] = c;
                        end
                end           
        end
endtask
/***********************************************************/


/***********************************************************/
// Redfilter BMP image
task RedfilterBMP(input [7:0]value);
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                a = image_in[y][x][0] - value;
                                if (a>255)
                                   image_out[y][x][0] = 0;
                                else
                                   image_out[y][x][0] = a/16;
                                image_out[y][x][1] = image_in[y][x][1]/16;
                                image_out[y][x][2] = image_in[y][x][2]/16;
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// Bluefilter BMP image 
task BluefilterBMP(input [7:0]value);
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                image_out[y][x][0] = image_in[y][x][0]/16;
                                b = image_in[y][x][1] - value;
                                if (b>255)
                                   image_out[y][x][1] = 0;
                                else
                                   image_out[y][x][1] = b/16;
                                image_out[y][x][2] = image_in[y][x][2]/16;
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// Greenfilter BMP image *
task GreenfilterBMP(input [7:0]value);
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                image_out[y][x][0] = image_in[y][x][0]/16; 
                                image_out[y][x][1] = image_in[y][x][1]/16;
                                c = image_in[y][x][2] - value;
                                if (c>255)
                                   image_out[y][x][2] = 0;
                                else
                                   image_out[y][x][2] = c/16;
                        end
                end
        end
endtask
/***********************************************************/

/***********************************************************/
// Red&greenfilter BMP image 
task RgfilterBMP;
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                image_out[y][x][0] = image_in[y][x][0]; 
                                image_out[y][x][1] = image_in[y][x][1];
                                image_out[y][x][2] = 0;
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// Red&bluefilter BMP image 
task RbfilterBMP;
        integer y, x, a,b,c;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                image_out[y][x][0] = image_in[y][x][0]; 
                                image_out[y][x][1] = 0;
                                image_out[y][x][2] = image_in[y][x][2];
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// pinkfilter (only at R = 255) BMP image
task pinkfilterBMP;
        integer y, x;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin 
                                if(image_in[y][x][0] > 0) begin
                                   image_out[y][x][0] = 255; 
                                   image_out[y][x][1] = 20;
                                   image_out[y][x][2] = 147;
                                end
                        end
                end
        end
endtask
/***********************************************************/


/***********************************************************/
// Convert Black&While to 24bit bitmap *
task BWto24BMP;
        integer  y, x, a;
        begin
                for (y=0; y<biHeight*4; y=y+1) begin
                        for (x=0; x<biWidth; x=x+1) begin
                                a = image_bw[y][x];
                                image_out[y][x][0] = a;
                                image_out[y][x][1] = a;
                                image_out[y][x][2] = a;
                        end
                end
        end
        
endtask
/***********************************************************/



/***********************************************************/
// Make binary        
task toBinary( input [7:0] intensity);
        
        integer y, x;
        begin

                for (y=0; y<biHeight*4; y=y+1)begin
                        for (x=0; x<biWidth; x=x+1) begin
                                if(image_bw[y][x] >= intensity) image_bw[y][x]=`HIGH;
                                else image_bw[y][x] = `LOW;
                        end
                end
        end
endtask
/***********************************************************/

//**** CALLING EACH FILTER ONE BY ONE AND OBSERVING THE OUTPUT *******//
initial begin      
 
        readBMP(read_filename);   //Read bmp file
        writeBMP(write_filename1,0); // write bmp file without filter using 0 as signal.
  
        //using signal as 1 to write the output color matrix into bmp after we apply a filter .
        BMPto256BW; 
        BWto24BMP; 
        writeBMP(write_filename2,1);

        toBinary(INTENSITY);
        BWto24BMP;
        writeBMP(write_filename3,1);
        
        invertBMP;  
        writeBMP(write_filename4,1);
         
        brightnessBMP(40,1);
        writeBMP(write_filename5,1);

        RedfilterBMP(254);
        writeBMP(write_filename6,1);

        BluefilterBMP(254);
        writeBMP(write_filename7,1);

        GreenfilterBMP(254);
        writeBMP(write_filename8,1);

        RgfilterBMP;
        writeBMP(write_filename9,1);

        RbfilterBMP;
        writeBMP(write_filename10,1);

        pinkfilterBMP;
        writeBMP(write_filename11,1);
end

endmodule