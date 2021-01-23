/*
Header file containing definitions for C interface of mpc_1_forces,
 a fast costumized optimization solver.
*/

#ifndef mpc_1_forces_H
#define mpc_1_forces_H

#include <stdio.h>

/* For Visual Studio 2015 Compatibility */
#if (_MSC_VER >= 1900)
FILE * __cdecl __iob_func(void);
#endif
/* DATA TYPE ------------------------------------------------------------*/
typedef double mpc_1_forces_float;

#ifndef SOLVER_STANDARD_TYPES
#define SOLVER_STANDARD_TYPES

typedef signed char solver_int8_signed;
typedef unsigned char solver_int8_unsigned;
typedef char solver_int8_default;
typedef signed short int solver_int16_signed;
typedef unsigned short int solver_int16_unsigned;
typedef short int solver_int16_default;
typedef signed int solver_int32_signed;
typedef unsigned int solver_int32_unsigned;
typedef int solver_int32_default;
typedef signed long long int solver_int64_signed;
typedef unsigned long long int solver_int64_unsigned;
typedef long long int solver_int64_default;

#endif

/* SOLVER SETTINGS ------------------------------------------------------*/
/* print level */
#ifndef SET_PRINTLEVEL_mpc_1_forces
#define SET_PRINTLEVEL_mpc_1_forces    (0)
#endif

/* PARAMETERS -----------------------------------------------------------*/
/* fill this with data before calling the solver! */
typedef struct
{
	/* column vector of length 3 */
	mpc_1_forces_float x0[3];

} mpc_1_forces_params;


/* OUTPUTS --------------------------------------------------------------*/
/* the desired variables are put here by the solver */
typedef struct
{
	/* matrix of size [2 x 29] (column major format) */
	mpc_1_forces_float output1[58];

} mpc_1_forces_output;


/* SOLVER INFO ----------------------------------------------------------*/
/* diagnostic data from last interior point step */
typedef struct
{
	/* iteration number */
	solver_int32_default it;

	/* number of iterations needed to optimality (branch-and-bound) */
	solver_int32_default it2opt;

	/* inf-norm of equality constraint residuals */
	mpc_1_forces_float res_eq;

	/* inf-norm of inequality constraint residuals */
	mpc_1_forces_float res_ineq;

	/* primal objective */
	mpc_1_forces_float pobj;

	/* dual objective */
	mpc_1_forces_float dobj;

	/* duality gap := pobj - dobj */
	mpc_1_forces_float dgap;

	/* relative duality gap := |dgap / pobj | */
	mpc_1_forces_float rdgap;

	/* duality measure */
	mpc_1_forces_float mu;

	/* duality measure (after affine step) */
	mpc_1_forces_float mu_aff;

	/* centering parameter */
	mpc_1_forces_float sigma;

	/* number of backtracking line search steps (affine direction) */
	solver_int32_default lsit_aff;

	/* number of backtracking line search steps (combined direction) */
	solver_int32_default lsit_cc;

	/* step size (affine direction) */
	mpc_1_forces_float step_aff;

	/* step size (combined direction) */
	mpc_1_forces_float step_cc;

	/* solvertime */
	mpc_1_forces_float solvetime;

} mpc_1_forces_info;


/* SOLVER FUNCTION DEFINITION -------------------------------------------*/

#ifdef __cplusplus
extern "C" {
#endif

/* examine exitflag before using the result! */
extern solver_int32_default mpc_1_forces_solve(mpc_1_forces_params *params, mpc_1_forces_output *output, mpc_1_forces_info *info, FILE *fs);

#ifdef __cplusplus
}
#endif

#endif /* mpc_1_forces_H */
