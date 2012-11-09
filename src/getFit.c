//============================================================================
// Name        : getFit.c
// Author      : Thomas Cokelaer
//============================================================================

#include <R.h>
#include <Rinternals.h>
#include <stdio.h>


SEXP getFit (

	SEXP nCond_in,
	SEXP nSignals_in,
	SEXP nReacs_in,
	SEXP nSpecies_in,
	SEXP nReacsCut_in,
	
	SEXP simResT0_in,
	SEXP simResT1_in,

    SEXP cnolist0_in,
    SEXP cnolist1_in,

    SEXP interMat_in,
    SEXP interMatCut_in,

    SEXP sizeFac_in,
    SEXP NAFac_in
) {
	
	SEXP simResults;
	
	int counter = 0;
	int i = 0;
	int j = 0;
	int curr_max = 0;
	int or_max = 0;
	int selection[40];
	int selCounter = 0;
	double *rans;
	int NAs = 0; //count NAs in simResults
	int nCond = INTEGER(nCond_in)[0];
	int nSignals = INTEGER(nSignals_in)[0];
	int nReacs = INTEGER(nReacs_in)[0];
	int nReacsCut = INTEGER(nReacsCut_in)[0];
	int nSpecies = INTEGER(nSpecies_in)[0];

	float NAFac = REAL(NAFac_in)[0];
    float sizeFac = REAL(sizeFac_in)[0];

    int nInTot = 0;
    int nInputs = 0;

    int NAPen = 0.;
    int nDataPts = 0;
    int nDataP = 0; // count NAs in cnolist
    float sizePen; 
    float score;

    counter = 0;
    for (i=0; i<nReacs*nSpecies; i++){
        if (INTEGER(interMat_in)[counter++] == -1){
            nInTot +=1;
        }
    }
    counter = 0;
    for (i=0; i<nReacsCut*nSpecies; i++){
        if (INTEGER(interMatCut_in)[counter++] == -1){
            nInputs +=1;
        }
    }

	counter=0;
	float **cnolist0;
    cnolist0 = (float**) malloc(nCond * sizeof(float*));
    for (i = 0; i < nCond; i++) {
	    cnolist0[i] = (float*) malloc(nSignals * sizeof(float));
	    for (j = 0; j < nSignals; j++) {
	        cnolist0[i][j] = REAL(cnolist0_in)[j+nSignals*i];
        }
	}

	counter=0;
	float **cnolist1;
    cnolist1 = (float**) malloc(nCond * sizeof(float*));
    for (i = 0; i < nCond; i++) {
	    cnolist1[i] = (float*) malloc(nSignals * sizeof(float));
	    for (j = 0; j < nSignals; j++) {
	        cnolist1[i][j] = REAL(cnolist1_in)[j+nSignals*i];
        }
	}

	counter=0;
	float **simResT0;
    simResT0 = (float**) malloc(nCond * sizeof(float*));
    for (i = 0; i < nCond; i++) {
	    simResT0[i] = (float*) malloc(nSignals * sizeof(float));
	    for (j = 0; j < nSignals; j++) {
	        simResT0[i][j] = REAL(simResT0_in)[j+nSignals*i];
        }
    }

	counter=0;
	float **simResT1;
    simResT1 = (float**) malloc(nCond * sizeof(float*));
    for (i = 0; i < nCond; i++) {
	    simResT1[i] = (float*) malloc(nSignals * sizeof(float));
	    for (j = 0; j < nSignals; j++) {
	        simResT1[i][j] = REAL(simResT1_in)[j+nSignals*i];
            if (ISNAN(simResT1[i][j])){
                NAs += 1;
            }
        }
    }
    NAPen = NAFac * NAs;
    nDataPts = nCond * nSignals;


    float deviationPen=0.;
	counter=0;
    float r;
    for (i = 0; i < nCond; i++) {
	    for (j = 0; j < nSignals; j++) {
            if (!ISNAN(cnolist0[i][j])){
	            r =  simResT0[i][j] - cnolist0[i][j];
                deviationPen += r*r;
            }

            if (!ISNAN(cnolist1[i][j])){
	            r = (simResT1[i][j] - cnolist1[i][j]);
                deviationPen += r*r;
                nDataP+=1;
            }
        }
    }
    deviationPen/=2.;

    sizePen = (float)(nDataPts*sizeFac*nInputs)/nInTot;
    score = deviationPen + NAPen + sizePen;
    score /= (float)nDataP;

	//============================================================================


 	PROTECT(simResults = allocMatrix(REALSXP, 1, 1));
	rans = REAL(simResults);
	rans[0] = score;
	
	
	for (i = 0; i < nCond; i++) {
		free(cnolist0[i]);
	}
	free(cnolist0);
	
	for (i = 0; i < nCond; i++) {
		free(cnolist1[i]);
	}
	free(cnolist1);
	
	for (i = 0; i < nCond; i++) {
		free(simResT0[i]);
	}
	free(simResT0);

	for (i = 0; i < nCond; i++) {
		free(simResT1[i]);
	}
	free(simResT1);


	UNPROTECT(1);
	return simResults;

}
