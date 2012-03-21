//+------------------------------------------------------------------+
//|                                                  FiboCluster 1.1 |
//|                             Copyright © 2011, Foreksjusz Trajder |
//|                                  http://foreksjusz.blogspot.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2011, Foreksjusz Trajder"
#property link      "http://foreksjusz.blogspot.com/"

#property indicator_chart_window

extern int       Match_Precision  = 2;                      //Pips Percision of cluster
extern int       Levels_Density = 2;                        //The number of Fibonacci levels consisting of a cluster
extern bool      Paint_Cluster_Line = FALSE;                //Paint horizontal lines
extern bool      Remove_All_Obj_Fibos = FALSE;              //Remove all obj Fibos from chart


double fiboPriceClusters[100][100], fiboClusterLevels[100][100], objClusterLevels[100][100];
int clusterIndex = 0, levelsIndexes[100];


/**
* Function find fibonacci objects [Retracement,Expansion]
*/

void getFiboObjects(string &objFibos[]){
      
   int arrIndex = 0;
   for(int i=0; i<ObjectsTotal(); i++) {
  
      if(ObjectType(ObjectName(i)) == OBJ_EXPANSION || ObjectType(ObjectName(i)) == OBJ_FIBO) {
         
         ArrayResize(objFibos, arrIndex+1);
         objFibos[arrIndex] = ObjectName(i);
         arrIndex++;
         
      }
   } 
}

void findMatchNodes(string objFibos[]){
   
   int fiboLevels;
   double fiboLevel, fiboLevelPrice;
   
   for(int i=0; i<ArraySize(objFibos); i++){
      
      fiboLevels = ObjectGet(objFibos[i],OBJPROP_FIBOLEVELS);
          
      for(int j=0; j<fiboLevels; j++){
         
         fiboLevel = ObjectGet(objFibos[i],OBJPROP_FIRSTLEVEL+j);
         fiboLevelPrice = getPriceByFiboLevel(objFibos[i],fiboLevel);
         checkMatchNodes(objFibos, i, fiboLevelPrice, fiboLevel);
         
      }
      
   }

}


void checkMatchNodes(string objFibos[], int currentObjFiboIndex, double currentFiboLevelPrice, double currentFiboLevel){
   
   int fiboLevels, levelIndex = 1, percisionLen;
   double fiboLevel, fiboLevelPrice, matchPrecision, clusterPrices[], clusterLevels[], clusterFiboObj[];
   ArrayResize(clusterPrices, levelIndex);
   ArrayResize(clusterLevels, levelIndex);
   
   clusterPrices[0] = currentFiboLevelPrice; 
   clusterLevels[0] = currentFiboLevel;
   clusterFiboObj[0] = currentObjFiboIndex;
   
   percisionLen = StringLen(DoubleToStr(Match_Precision,0));
   
   switch(percisionLen)                                 
   {                                           
      case 1 : matchPrecision = StrToDouble("0.000" + Match_Precision);    break;
      case 2 : matchPrecision = StrToDouble("0.00" + Match_Precision);    break;
      case 3 : matchPrecision = StrToDouble("0.0" + Match_Precision);  break;
      case 4 : matchPrecision = StrToDouble("0." + Match_Precision);  break;
      default: Alert("Match_Precision invalid");  
   }
   
   
   matchPrecision = StrToDouble("0.000" + Match_Precision);
  
   for(int i=currentObjFiboIndex+1; i<ArraySize(objFibos); i++){
         
      fiboLevels = ObjectGet(objFibos[i],OBJPROP_FIBOLEVELS);
         
      for(int j=0; j<fiboLevels; j++){   
         
         fiboLevel = ObjectGet(objFibos[i],OBJPROP_FIRSTLEVEL+j);
         fiboLevelPrice = getPriceByFiboLevel(objFibos[i],fiboLevel);
         
         
         if((currentFiboLevelPrice <= (fiboLevelPrice + matchPrecision)) &&  ((fiboLevelPrice - matchPrecision) <= currentFiboLevelPrice)){
          
            ArrayResize(clusterPrices, levelIndex+1);
            ArrayResize(clusterLevels, levelIndex+1);
            ArrayResize(clusterFiboObj, levelIndex+1);
            clusterPrices[levelIndex] = fiboLevelPrice;
            clusterLevels[levelIndex] = fiboLevel;
            clusterFiboObj[levelIndex] = i;
            
            levelIndex++;           
         
         }
      }
   }
   
   if(ArraySize(clusterPrices) >= Levels_Density){
      
      for(i=0; i<levelIndex; i++){
         fiboPriceClusters[clusterIndex][i] = clusterPrices[i];
         fiboClusterLevels[clusterIndex][i] = clusterLevels[i];
         objClusterLevels[clusterIndex][i] = clusterFiboObj[i];
      }
      levelsIndexes[clusterIndex] = levelIndex;
      
      clusterIndex++;
     
   }
   
}


double getPriceByFiboLevel(string objFibo, double fiboLevel){

   double priceBegin, priceEnd, priceExpansion, segmentLength;
 
   priceBegin = ObjectGet(objFibo,OBJPROP_PRICE1);
   priceEnd = ObjectGet(objFibo,OBJPROP_PRICE2);
  
   segmentLength = MathAbs(priceBegin - priceEnd);
   
   if(ObjectType(objFibo) == OBJ_FIBO) {
   
      if(priceBegin > priceEnd){
         return (NormalizeDouble((segmentLength*fiboLevel) + priceEnd,4));
      } else {
         return (NormalizeDouble(priceEnd - (segmentLength*fiboLevel),4));
      }
   
   } else if(ObjectType(objFibo) == OBJ_EXPANSION) {
      priceExpansion = ObjectGet(objFibo,OBJPROP_PRICE3);
     
      if(priceExpansion > priceEnd){
          return (NormalizeDouble(priceExpansion - (segmentLength*fiboLevel),4));
      } else {
          return (NormalizeDouble((segmentLength*fiboLevel) + priceExpansion,4));
      }
      
   }
   
}


int getCountFiboLeves(int objIndex, double &levels[]){
    
    int levelsCount = 0;
    
    for(int i=0; i<clusterIndex; i++){
      for(int j=0; j<levelsIndexes[i]; j++){
         if(objClusterLevels[i][j] == objIndex){
            levelsCount++;
            
            ArrayResize(levels, ArraySize(levels)+1);
            levels[ArraySize(levels)-1] = fiboClusterLevels[i][j];
           
         }   
      }
    }
    return(levelsCount);

}

void removeOutClusterFiboLevels(string objFibos[]){
   
   int LevelsCount = 0;
   double levels[];
   
    for(int i=0; i<ArraySize(objFibos); i++){
      ArrayResize(levels,0);
      
      LevelsCount = getCountFiboLeves(i,levels);
      if(LevelsCount == 0){
      
         ObjectDelete(objFibos[i]);
      
      } else {
       
        ObjectSet(objFibos[i],OBJPROP_FIBOLEVELS,LevelsCount);      
        for(int j=0; j<ArraySize(levels); j++){
            ObjectSet(objFibos[i], OBJPROP_FIRSTLEVEL+j, levels[j]);
            ObjectSetFiboDescription(objFibos[i], j, DoubleToStr(levels[j], 3));
           
        }
      }
    
    }

}

void paintClusters(){
   
   string fiboLevels, fiboLevel;
   
   for(int i=0; i<clusterIndex; i++){
     
     ObjectCreate("Fibo_Cluster_"+i, OBJ_HLINE,0,0,fiboPriceClusters[i][0]);
     ObjectSet("Fibo_Cluster_"+i, OBJPROP_COLOR, GreenYellow);
     ObjectSet("Fibo_Cluster_"+i, OBJPROP_WIDTH,3);
     
     for(int j=0; j<levelsIndexes[i]; j++){
                 
         if(j==0){
            fiboLevels = "Cluster_levels:" + DoubleToStr(fiboClusterLevels[i][j],3);
         } else {
            fiboLevels = fiboLevels + "," + DoubleToStr(fiboClusterLevels[i][j],3);
         }
         
     }
     
     ObjectSetText("Fibo_Cluster_"+i, fiboLevels, 16);
      
   }
}

void removeAllObjFibo(string objFibos[]){
   
   for(int i=0; i<ArraySize(objFibos); i++){
      ObjectDelete(objFibos[i]);
   }

}

int init()
  {

    string objFibos[];
   
    getFiboObjects(objFibos);
    
    findMatchNodes(objFibos);
   
    removeOutClusterFiboLevels(objFibos);
    
    if(Paint_Cluster_Line){
      paintClusters();
    }
     
    if(Remove_All_Obj_Fibos){
      removeAllObjFibo(objFibos);
    }

  }

int deinit()
  {

   return(0);
  }

int start()
  {
   return(0);
  }

