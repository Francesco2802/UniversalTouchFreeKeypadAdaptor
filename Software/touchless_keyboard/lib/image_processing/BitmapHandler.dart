
import 'package:bitmap/bitmap.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';


class BitmapHandler {

  List<List<List<int>>> bitmapData;
  List<List<int>> greyscaleBitmapData;
  List<List<int>> blurredBitmapData;

  List<List<int>> combinedEdgeData;
  List<List<int>> edgeAngleData;

  List<List<int>> nonMaxSuppressedEdgeData;

  int current_path_id = 1;
  List<List<int>> path_ID;

  List<Point> points;
  List<int> hilightedPaths;


  var height;
  var width;

  final edgeThreshold = 15;

  void init(Bitmap bitmap){

    points = [];
    hilightedPaths = [];

    width = bitmap.width;
    height = bitmap.height;

    bitmapData = List.generate(bitmap.height, (index) => List.generate(bitmap.width, (index) => List(bitmapPixelLength)));

    int offset = 0;

    for(int y=0; y<bitmap.height; y+=1){
      for(int x=0; x<bitmap.width; x+=1){
        for(int c=0;c<bitmapPixelLength; c+=1){

          bitmapData[y][x][c] = bitmap.content[offset];
          offset += 1;
    }}}
    generateGreyscaleImage();  
  }



  RectangleFrame searchPattern(List<List<int>> pattern) {

    int kernelSizeMaxMultiplier = min(15,min<int>(width, height)~/9);
    print("Max multiplier $kernelSizeMaxMultiplier");

    bool tagFound = false;

    int tagWidth=0, tagHeight=0, tagX=0, tagY=0;

    for (int multiplier=5; multiplier<kernelSizeMaxMultiplier; multiplier +=1) {
      
      print(multiplier);
      int kernel_size = 9*multiplier;

      for (int startingPointY = 0; startingPointY<height-kernel_size; startingPointY+=1) {
        for (int startingPointX = 0; startingPointX<width-kernel_size; startingPointX+=1) {


          int blacks=0, whites=0, blackPixels=0, whitePixels=0;

          Point startingPoint = new Point(startingPointX, startingPointY);

          for (int ky=0; ky<9; ky+=1) {
            for (int kx=0; kx<9; kx+=1) {

              for (int my=0; my<=multiplier; my+=1) {
                for (int mx=0; mx<=multiplier; mx+=1) {

                  if (pattern[ky][kx] == 0) {
                    blacks += greyscaleBitmapData[startingPoint.y+ky*multiplier+my][startingPoint.x+kx*multiplier+mx];
                    blackPixels += 1;
                  } 
                  else {
                    whites += 210-greyscaleBitmapData[startingPoint.y+ky*multiplier+my][startingPoint.x+kx*multiplier+mx];
                    whitePixels += 1;
                  }
                }
              }
            }
          }

          if (blackPixels != 0 && whitePixels != 0 && whites / whitePixels < 30 && blacks/blackPixels < 120) {
            print("TAG FOUND! -> (${startingPoint.x},${startingPoint.y}) M: $multiplier <${whites / whitePixels}, ${blacks/blackPixels}>");
            tagFound = true;

            tagX = startingPoint.x;
            tagY = startingPoint.y;
            tagWidth = 9*multiplier;
            tagHeight = 9*multiplier;

            int minTagX, maxTagX, minTagY, maxTagY;
          
            minTagX = tagX + tagWidth ~/4;
            int y = tagY + tagHeight ~/2;
            int x = tagX + tagWidth ~/2;
            
            while(greyscaleBitmapData[y][minTagX] < 60 && minTagX>0) minTagX--;
            while(greyscaleBitmapData[y][minTagX] > 160 && minTagX>0) minTagX--;
            
            maxTagX = tagX + tagWidth *3 ~/4;
            while(greyscaleBitmapData[y][maxTagX] < 60 && maxTagX<width) maxTagX++;
            while(greyscaleBitmapData[y][maxTagX] > 160 && maxTagX<width) maxTagX++;

            minTagY = tagY + tagHeight ~/4;
            while(greyscaleBitmapData[minTagY][x] < 60 && minTagY>0) minTagY--;
            while(greyscaleBitmapData[minTagY][x] > 160 && minTagY>0) minTagY--;

            maxTagY = tagY + tagHeight *3 ~/4;
            while(greyscaleBitmapData[maxTagY][x] < 60 && maxTagY<height) maxTagY++;
            while(greyscaleBitmapData[maxTagY][x] > 160 && maxTagY<height) maxTagY++;

            tagWidth = maxTagX - minTagX;
            tagHeight = maxTagY - minTagY;

            for(int y=0; y<tagHeight; y+=1){
                path_ID[y+minTagY][minTagX] = -1;
                path_ID[y+minTagY][maxTagX] = -1;
            }
            for(int x=0; x<tagWidth; x+=1){
                path_ID[minTagY][minTagX+x] = -1;
                path_ID[minTagY+tagHeight][minTagX+x] = -1;
            }

            return RectangleFrame(minTagX, minTagY, tagWidth, tagHeight);
          }
        }
        if (tagFound)break;
      }
      if (tagFound)break;
    }
    return null;
  }


  Uint8List getGreyscaleBitmalAsIntList(){

    Uint8List dataList = Uint8List(width*height*4);

    for(int y=0; y<height; y+=1){
      for(int x=0; x<width; x+=1){
        for(int c=0;c<4; c++){
        dataList[y*width*4 + x*4 + c] = greyscaleBitmapData[y][x];
        }
      }
    }
    return dataList;
  }

  Uint8List getBlurredBitmapAsIntList() {
    Uint8List dataList = Uint8List(width*height*4);

    for(int y=0; y<height; y+=1){
      for(int x=0; x<width; x+=1){
        for(int c=0;c<4; c++){
        dataList[y*width*4 + x*4 + c] = blurredBitmapData[y][x];
        }
      }
    }
    return dataList;
  }

  Uint8List getCombineEdgesBitmapAsIntList() {
    Uint8List dataList = Uint8List(width*height*4);

    for (int y=0; y<height; y+=1) {
      for (int x=0; x<width; x+=1) {

        if(combinedEdgeData[y][x] > 15){
          Color colorFromAngle = convertAngleToColor(edgeAngleData[y][x]);

          dataList[y*width*4 + x*4+0] = colorFromAngle.red;
          dataList[y*width*4 + x*4+1] = colorFromAngle.green;
          dataList[y*width*4 + x*4+2] = colorFromAngle.blue;
          dataList[y*width*4 + x*4+3] = 255;
        }
        else {
          for(int c=0;c<4; c++){
            dataList[y*width*4 + x*4 + c] = 255;
          }
        }
      }
    }
    return dataList;
  }

  Uint8List getNonMaxSuppressedBitmapAsIntList() {
    Uint8List dataList = Uint8List(width*height*4);

    for (int y=0; y<height; y+=1) {
      for (int x=0; x<width; x+=1) {

        if(nonMaxSuppressedEdgeData[y][x] > 15){
          Color colorFromAngle = convertAngleToColor(edgeAngleData[y][x]);

          dataList[y*width*4 + x*4+0] = colorFromAngle.red;
          dataList[y*width*4 + x*4+1] = colorFromAngle.green;
          dataList[y*width*4 + x*4+2] = colorFromAngle.blue;
          dataList[y*width*4 + x*4+3] = 255;
        }
        else {
          for(int c=0;c<3; c++){
            dataList[y*width*4 + x*4 + c] = bitmapData[y][x][c];
          }
          dataList[y*width*4 + x*4 + 3] = 100;
        }
      }
    }
    return dataList;
  }


  void drawPoint(int x, int y){
    points.add(Point(x,y));
  }

  Uint8List getClosedPathBitmapAsIntList() {
    Uint8List dataList = Uint8List(width*height*4);

    for (int y=0; y<height; y+=1) {
      for (int x=0; x<width; x+=1) {

        if(path_ID[y][x] > 0){
          
          Color colorFromAngle = convertAngleToColor(0 /*edgeAngleData[y][x]*/);

          if(hilightedPaths.indexOf(path_ID[y][x]) != -1){
            dataList[y*width*4 + x*4+0] = 0;
            dataList[y*width*4 + x*4+1] = 200;
            dataList[y*width*4 + x*4+2] = 200;
            dataList[y*width*4 + x*4+3] = 255;
          }
          else {
            dataList[y*width*4 + x*4+0] = colorFromAngle.red;
            dataList[y*width*4 + x*4+1] = colorFromAngle.green;
            dataList[y*width*4 + x*4+2] = colorFromAngle.blue;
            dataList[y*width*4 + x*4+3] = 255;
          }
        }
        else if(path_ID[y][x] == -1){
          dataList[y*width*4 + x*4+0] = 200;
            dataList[y*width*4 + x*4+1] = 50;
            dataList[y*width*4 + x*4+2] = 200;
            dataList[y*width*4 + x*4+3] = 255;
        }
        else {
          for(int c=0;c<3; c++){
            dataList[y*width*4 + x*4 + c] = bitmapData[y][x][c];
          }
          dataList[y*width*4 + x*4 + 3] = 100;
        }
      }
    }

    if(points != null){
      for(int i=0;i<points.length; i+=1){
        dataList[points[i].y*width*4 + points[i].x*4+0] = 0;
        dataList[points[i].y*width*4 + points[i].x*4+1] = 200;
        dataList[points[i].y*width*4 + points[i].x*4+2] = 200;
        dataList[points[i].y*width*4 + points[i].x*4+3] = 255;
      }
    }
    return dataList;
  }

  void generateGreyscaleImage() {
    greyscaleBitmapData = List.generate(height, (i)=>List(width));

    for(int y=0;y<height; y+=1){
      for(int x=0;x<width; x+=1){
        int red, green, blue;

        red = bitmapData[y][x][0];
        green = bitmapData[y][x][1];
        blue = bitmapData[y][x][2];

        greyscaleBitmapData[y][x] = (0.3*red.toDouble() + 0.59*green.toDouble() + 0.11*blue.toDouble()).toInt();
      }
    }
  }


  void hilightPath(int pathID){

    hilightedPaths.add(pathID);
  }

  void unhilightLastPath () {
    hilightedPaths.removeLast();
  }


  
  void applyGaussianBlurFilter(int kernelSize) {

    if(kernelSize % 2 == 0)kernelSize -= 1;
    int halfSize = (kernelSize-1)~/2.0;

    List<double> kernel = List.generate(kernelSize, (index) => 0.0);
    List<List<double>> verticalBlur = List.generate(height, (i)=>List(width));
    blurredBitmapData = List.generate(height, (i)=>List(width));
    
    double c = 0.95;
    double min = 100;

    // calculate gaussian kernel values
    for(int i = -halfSize; i<=halfSize; i+=1){
      kernel[i+halfSize] = exp( -(pow(i, 2) / (2*pow(c, 2)) ));
      if(kernel[i+halfSize]>0 && kernel[i+halfSize] < min)min = kernel[i+halfSize];
    }
    //normalize the calculated values
    double multiplier = 1.0/min;
    double divider = 0;
    for(int i = 0; i<kernelSize; i+=1){
      kernel[i] *= multiplier;
      divider += kernel[i];
    }
    // blur vertical pass
    for(int y=0;y<height; y+=1){
      for(int x=0; x<width; x+=1){

        if(y>=halfSize && x>=halfSize && y<height-halfSize && x<width-halfSize){
          double sum = 0;
          for(int i=-halfSize; i<=halfSize; i+=1){
            sum += kernel[i+halfSize] * greyscaleBitmapData[y+i][x];
          }
          verticalBlur[y][x] = sum/divider;
        }
        else verticalBlur[y][x] = 0;
      }
    }
    // blur horizontal pass
    for(int y=0;y<height; y+=1){
      for(int x=0; x<width; x+=1){

        if(y>=halfSize && x>=halfSize && y<height-halfSize && x<width-halfSize){

          double sum = 0;
          for(int i=-halfSize; i<=halfSize; i+=1){
            sum += verticalBlur[y][x+i] * kernel[i+halfSize];
          }
          blurredBitmapData[y][x] = sum~/divider;
        }
        else blurredBitmapData[y][x] = 0;
      }
    }
  }


  void performSobelEdgeDetection () {

    List<List<int>> VerticalSobelEdgeKernelValues = [
      [1,0,-1],
      [2,0,-2],
      [1,0,-1]
    ];
    List<List<int>> HorizontalSobelEdgeKernelValues = [
      [-1,-2,-1],
      [ 0, 0, 0],
      [ 1, 2, 1]
    ];

    final sobelKernelSize = 3;

    List<List<int>> verticalEdgeData   = List.generate(height, (index) => List(width));
    List<List<int>> horizontalEdgeData = List.generate(height, (index) => List(width));

    combinedEdgeData = List.generate(height, (index) => List(width));
    edgeAngleData    = List.generate(height, (index) => List(width));

    nonMaxSuppressedEdgeData = List.generate(height, (index) => List(width));

    for(int y=0;y<height; y+=1){
      for(int x=0;x<width; x+=1){

        verticalEdgeData[y][x] = 0;
        if(y>1 && x>1 && y<height-2 && x<width-2){
          
          for (int i=0; i<sobelKernelSize; i++) {
            for (int j=0; j<sobelKernelSize; j++) {
              verticalEdgeData[y][x] += (blurredBitmapData[y+i-1][x+j-1] * VerticalSobelEdgeKernelValues[i][j]);
          }}
        }
      }
    }
    for(int y=0;y<height; y+=1){
      for(int x=0;x<width; x+=1){

        horizontalEdgeData[y][x] = 0;
        if(y>1 && x>1 && y<height-2 && x<width-2){

          for (int i=0; i<sobelKernelSize; i++) {
            for (int j=0; j<sobelKernelSize; j++) {
              horizontalEdgeData[y][x] += (blurredBitmapData[y+i-1][x+j-1] * HorizontalSobelEdgeKernelValues[i][j]);
          }}
        }
      }
    }

    double edgeAngle;
    for(int y=0;y<height; y+=1){
      for(int x=0;x<width; x+=1){

        int verticalEdge = verticalEdgeData[y][x];
        int horizontalEdge = horizontalEdgeData[y][x];
        edgeAngleData[y][x] = 0;

        int combinedEdge = (sqrt( pow(verticalEdge, 2) + pow(horizontalEdge, 2))).toInt();

        if (horizontalEdge != 0 && verticalEdge != 0) {
          edgeAngle = atan((verticalEdge).toDouble() / (horizontalEdge).toDouble()) * 57.296;

          if (verticalEdge>0 && horizontalEdge>0) {
            edgeAngle -= 180;
          }
          if (verticalEdge>0 && horizontalEdge<0) {
            edgeAngle += 180;
          }
          if (edgeAngle > 0 && edgeAngle < 90)edgeAngle = 90-edgeAngle;
          if (edgeAngle > 90 && edgeAngle < 180)edgeAngle = 90 + 180-edgeAngle;

          if (edgeAngle < 0 && edgeAngle > -90)edgeAngle = -(edgeAngle+90);
          if (edgeAngle < -90 && edgeAngle > -180)edgeAngle = -90 - (edgeAngle+180);
        } else if (verticalEdge == 0) {
          if (horizontalEdge < 0)edgeAngle = 90;
          else edgeAngle = -90;
        } else if (horizontalEdge == 0) {
          if (verticalEdge < 0) edgeAngle = 0;
          else edgeAngle = 180;
        } else edgeAngle = 0;

        if (edgeAngle<0)edgeAngle = 360 + edgeAngle;

        if (combinedEdge >= edgeThreshold) {
          combinedEdgeData[y][x] = combinedEdge;
          edgeAngleData[y][x] = edgeAngle.toInt();
        } else {
          combinedEdgeData[y][x] = 0;
          edgeAngleData[y][x] = 0;
        }
      }
    }
  }


  void performNonMaximaSuppression () {

    for (int y=0; y<height; y += 1) {
      for (int x=0; x<width; x += 1) {

        int edgeValue = combinedEdgeData[y][x];
        double edgeAngle = edgeAngleData[y][x].toDouble();

        if (edgeValue > edgeThreshold) {

          if ((edgeAngle >= 337 || edgeAngle < 22) || (edgeAngle >= 158 && edgeAngle<202)) {
            if (edgeValue > combinedEdgeData[y][x+1] && edgeValue > combinedEdgeData[y][x-1])nonMaxSuppressedEdgeData[y][x] = edgeValue;

            else if (edgeValue == combinedEdgeData[y][x+1] || edgeValue == combinedEdgeData[y][x-1]) {
              if (nonMaxSuppressedEdgeData[y][x-1] == 0 && nonMaxSuppressedEdgeData[y][x+1] == 0)nonMaxSuppressedEdgeData[y][x] = edgeValue;
              else nonMaxSuppressedEdgeData[y][x] = 0;
              ;
            } else nonMaxSuppressedEdgeData[y][x] = 0;
          } else if ((edgeAngle >= 22 && edgeAngle < 67) || (edgeAngle >= 202 && edgeAngle < 247)) {

            if (edgeValue > combinedEdgeData[y-1][x+1] && edgeValue > combinedEdgeData[y+1][x-1])nonMaxSuppressedEdgeData[y][x] = edgeValue;
            else nonMaxSuppressedEdgeData[y][x] = 0;
          } else if ((edgeAngle >= 67 && edgeAngle < 112) || (edgeAngle >= 247 && edgeAngle < 292)) {

            if (edgeValue > combinedEdgeData[y-1][x] && edgeValue > combinedEdgeData[y+1][x])nonMaxSuppressedEdgeData[y][x] = edgeValue;

            else if (edgeValue == combinedEdgeData[y-1][x] || edgeValue == combinedEdgeData[y+1][x]) {
              if (nonMaxSuppressedEdgeData[y-1][x] == 0 && nonMaxSuppressedEdgeData[y+1][x] == 0)nonMaxSuppressedEdgeData[y][x] = edgeValue;
              else nonMaxSuppressedEdgeData[y][x] = 0;
            } else nonMaxSuppressedEdgeData[y][x] = 0;
          } else if ((edgeAngle >= 112 && edgeAngle < 158) || (edgeAngle >= 292 && edgeAngle < 337)) {

            if (edgeValue > combinedEdgeData[y-1][x-1] && edgeValue > combinedEdgeData[y+1][x+1])nonMaxSuppressedEdgeData[y][x] = edgeValue;
            else nonMaxSuppressedEdgeData[y][x] = 0;
          }
        }else nonMaxSuppressedEdgeData[y][x] = 0;
    } }
  }


  void lookForClosedPaths () {

      List<List<LookForClosedPathPixelStructure>> matrix = List.generate(height, (index) => List(width));

      for (int y=0; y<height; y += 1) {
        for (int x=0; x<width; x += 1) { 
          matrix[y][x] = new LookForClosedPathPixelStructure();
        }
      }
      Point left_edge = new Point(20, 20);
      Point right_edge = new Point(width-20, height-20);

      Point startingPoint;
      Point thisPoint = new Point(left_edge.x, left_edge.y);

      path_ID = List.generate(height, (index) => List(width));
      current_path_id = 1;

      int closedPathMinIterations = 40;


      for(int y=0;y<height; y+=1){
        for(int x=0;x<width; x+=1){
          path_ID[y][x] = 0;
        }
      }

      // look for the first valid edge
      bool EOB = false;
      print("SEARCH CLOSE PATHS");
      while (EOB == false) {


        //look for the first valid edge

        while (nonMaxSuppressedEdgeData[thisPoint.y][thisPoint.x] < edgeThreshold || path_ID[thisPoint.y][thisPoint.x] != 0) {
          thisPoint.x += 1;

          if (thisPoint.x >= right_edge.x) {
            thisPoint.x = left_edge.x;
            thisPoint.y += 1;
          }
          if (thisPoint.y >= right_edge.y) {
            print("REACHED THE END OF THE BITMAP -");
            EOB = true;
            break;
          }
        }
        if (EOB)break;

        startingPoint = new Point(thisPoint.x, thisPoint.y);  // save the first valid edge pixel as starting point

        bool foundClosedPath = false;
        int iterations = 0;

        while (true) {

          bool needToBreak = false;
          foundClosedPath = false;

          for (int s=0; s<3; s++) {

            int s_dim = s+1;

            for (int i=-s_dim; i<(s_dim+1); i++) {

              for (int j=-s_dim; j<(s_dim+1); j++) {

                if (i==0 && j==0)continue;


                // if the current pixel is the start point, the path is closed
                if (thisPoint.y+i == startingPoint.y && thisPoint.x+j == startingPoint.x && iterations > closedPathMinIterations) {
                  foundClosedPath = true;
                  path_ID[thisPoint.y][thisPoint.x] = current_path_id;
                  break;
                }
                if (thisPoint.y+i > 4 && thisPoint.x+j > 4 &&  nonMaxSuppressedEdgeData[thisPoint.y+i][thisPoint.x+j] > edgeThreshold  && (path_ID[thisPoint.y+i][thisPoint.x+j] == 0)) {

                  path_ID[thisPoint.y][thisPoint.x] = current_path_id;
                  matrix[thisPoint.y+i][thisPoint.x+j].previousPoint = new Point(thisPoint.x, thisPoint.y);
                  //matrix[thisPoint.y][thisPoint.x].visitedDirections |= 1<<((i+1)*3 + j + 1);

                  thisPoint.x += j;
                  thisPoint.y += i;

                  iterations += 1;

                  needToBreak = true;
                  break;
                }
              }
              if (needToBreak || foundClosedPath)break;
              if(thisPoint.x < left_edge.x || thisPoint.x > right_edge.x || thisPoint.y < left_edge.y || thisPoint.y > right_edge.y){
                needToBreak = true;
                break;
              }
            }
            if (needToBreak || foundClosedPath)break;
          }
          if(thisPoint.x < left_edge.x || thisPoint.x > right_edge.x || thisPoint.y < left_edge.y || thisPoint.y > right_edge.y){
            break;
          }
          if (!needToBreak || foundClosedPath)break;
        }


        if (foundClosedPath) {
          //print("END -> close path!");

          current_path_id += 1;
        } else {
          //print("END");
          while (thisPoint.x != startingPoint.x || thisPoint.y != startingPoint.y) {
            matrix[thisPoint.y][thisPoint.x].visitedDirections = 0;

            path_ID[thisPoint.y][thisPoint.x] = 0;

            Point previousPoint =  new Point (matrix[thisPoint.y][thisPoint.x].previousPoint.x, matrix[thisPoint.y][thisPoint.x].previousPoint.y);
            matrix[thisPoint.y][thisPoint.x].previousPoint = null;

            thisPoint.x = previousPoint.x;
            thisPoint.y = previousPoint.y;
          } 
          path_ID[thisPoint.y][thisPoint.x] = 0;
        }

        thisPoint.x = startingPoint.x+1;
        thisPoint.y = startingPoint.y;

        if (thisPoint.x >= right_edge.x) {
          thisPoint.x = left_edge.x;
          thisPoint.y += 1;
        }
        if (thisPoint.y >= right_edge.y) {
          //print("REACHED THE END OF THE BITMAP");
          break;
        }
      }

      print("DONE -> found ${current_path_id-1} close paths");
  }



  int isPointInsidePath(int pointX, int pointY){
    //lookForClosedPaths();

    if (pointX > width || pointY > height) return 0;

    int xn=0, xp=0, yn = pointY, yp=0;

    int pathToSkip=0;
    int targetPathID = 0;

    List<int> path_ID_to_skip = [];

    while (true) {

      targetPathID = 0;

      while (yn>=0) {
        bool needToBreak = false;

        if (path_ID[yn][pointX] != 0) {

          bool skipPathID = false;

          path_ID_to_skip.forEach((element) {
            if(element == path_ID[yn][pointX]) skipPathID = true;
          });

          if (!skipPathID) {
            targetPathID = path_ID[yn][pointX];
            needToBreak = true;
            yn-=1;
            break;
          }
        }
        if (needToBreak)break;
        yn-=1;
      }
      if (targetPathID == 0)break;

      int found = 0;
      for (yp = pointY; yp < height; yp+=1) {
        if (path_ID[yp][pointX] == targetPathID) {
          found += 1;
          break;
        }
      }
      for (xn=pointX; xn >=0; xn -=1) {
        if (path_ID[pointY][xn] == targetPathID) {
          found += 1;
          break;
        }
      }
      for (xp=pointX; xp< width; xp += 1) {
        if (path_ID[pointY][xp] == targetPathID) {
          found += 1;
          break;
        }
      }
      if (found == 3) break;


      path_ID_to_skip.add(targetPathID);
      pathToSkip += 1;
    }

    if (targetPathID == 0)print("Click not in a closed path");

    else {

      print("Click in path -> ${targetPathID}");


    int minX = width, minY = height, maxX = 0, maxY = 0;

    for (int y=0; y<height; y += 1) {
      for (int x=0; x<width; x += 1) {

        if (path_ID[y][x] == targetPathID) {
          if (x > maxX)maxX = x;
          if (x < minX) minX = x;
          if (y> maxY)maxY = y;
          if (y<minY)minY = y;
        }
      }
    }
    return targetPathID;
  }
  return 0;
}





RectangleFrame getPathFrame(int pathID){

 int minX = height, minY = width, maxX = 0, maxY = 0;

 bool validPathID = false;

  for (int y=0; y<height; y += 1) {
    for (int x=0; x<width; x += 1) {

      if (path_ID[y][x] == pathID) {
        validPathID = true;

        if (x > maxX)maxX = x;
        if (x < minX) minX = x;
        if (y> maxY)maxY = y;
        if (y<minY)minY = y;
      }
    }
  }
  if(!validPathID)return null;
  return RectangleFrame(minX, minY, (maxX-minX), (maxY-minY));
}
































  Color convertAngleToColor(int angle) {
    if (angle < 0)angle = 360 + angle;
    while (angle>360)angle -= 360;

    int red = 0;
    if (angle < 120) {
      red = (255.0/120.0 * (120- angle)).toInt();
    } else if (angle > 240) {
      red = (255.0/120.0 * (angle-240)).toInt();
    }

    int green = 0;
    if (angle > 0 && angle<=120) {
      green = (255.0/120.0 * angle).toInt();
    } else if (angle >120 && angle <240) {
      green = (255.0/120.0 * (240-angle)).toInt();
    }

    int blue = 0;
    if (angle > 120 && angle<=240) {
      blue = (255.0/120.0 * (angle-120)).toInt();
    } else if (angle >240 && angle <360) {
      blue = (255.0/120.0 * (360-angle)).toInt();
    }

    return Color.fromRGBO(red, green, blue, 1.0);
  }



}



class LookForClosedPathPixelStructure {

  int visitedDirections;
  Point previousPoint;

  LookForClosedPathPixelStructure() {
    visitedDirections = 0;
  }
}

class Point {
  int x;
  int y;


  Point(int _x, int _y) {
    x = _x;
    y = _y;
  }
}


class RectangleFrame {
  int x;
  int y;
  int width;
  int height;

  int maxX;
  int maxY;
  int centerX;
  int centerY;

  RectangleFrame(int _x, int _y, int _width, int _height){

    x = _x;
    y = _y;
    width = _width;
    height = _height;

    maxX = x+width;
    maxY = y+height;

    centerX = x + width ~/2;
    centerY = y + height ~/2;
  }
}