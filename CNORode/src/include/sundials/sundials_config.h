/*
 * -----------------------------------------------------------------
 * $Revision: 1.4 $
 * $Date: 2007/12/19 20:34:00 $
 * ----------------------------------------------------------------- 
 * Programmer(s): Aaron Collier and Radu Serban @ LLNL
 * -----------------------------------------------------------------
 * Copyright (c) 2005, The Regents of the University of California.
 * Produced at the Lawrence Livermore National Laboratory.
 * All rights reserved.
 * For details, see the LICENSE file.
 *------------------------------------------------------------------
 * SUNDIALS configuration header file
 *------------------------------------------------------------------
 */

/* Define SUNDIALS version number */
#define SUNDIALS_PACKAGE_VERSION "2.6.0"

/* FCMIX: Define Fortran name-mangling macro for C identifiers.
 * Depending on the inferred scheme, one of the following six
 * macros will be defined:
 *     #define SUNDIALS_F77_FUNC(name,NAME) name
 *     #define SUNDIALS_F77_FUNC(name,NAME) name ## _
 *     #define SUNDIALS_F77_FUNC(name,NAME) name ## __
 *     #define SUNDIALS_F77_FUNC(name,NAME) NAME
 *     #define SUNDIALS_F77_FUNC(name,NAME) NAME ## _
 *     #define SUNDIALS_F77_FUNC(name,NAME) NAME ## __
 */
//#define F77_FUNC(name,NAME) name ## _
//#define F77_FUNC_(name,NAME) name ## _

/* FCMIX: Define Fortran name-mangling macro for C identifiers
 *        which contain underscores.
 */
//#define SUNDIALS_UNDERSCORE_ONE 1

/* Define precision of SUNDIALS data type 'realtype' 
 * Depending on the precision level, one of the following 
 * three macros will be defined:
 *     #define SUNDIALS_SINGLE_PRECISION 1
 *     #define SUNDIALS_DOUBLE_PRECISION 1
 *     #define SUNDIALS_EXTENDED_PRECISION 1
 */
#define SUNDIALS_DOUBLE_PRECISION 1

/* Use generic math functions 
 * If it was decided that generic math functions can be used, then
 *     #define SUNDIALS_USE_GENERIC_MATH 1
 * otherwise
 *     #define SUNDIALS_USE_GENERIC_MATH 0
 */
#define SUNDIALS_USE_GENERIC_MATH 1

/* Blas/Lapack available
 * If working libraries for Blas/lapack support were found, then
 *     #define SUNDIALS_BLAS_LAPACK 1
 * otherwise
 *     #define SUNDIALS_BLAS_LAPACK 0
 */
//#define SUNDIALS_BLAS_LAPACK 0

/* FNVECTOR: Allow user to specify different MPI communicator
 * If it was found that the MPI implementation supports MPI_Comm_f2c, then
 *      #define SUNDIALS_MPI_COMM_F2C 1
 * otherwise
 *      #define SUNDIALS_MPI_COMM_F2C 0
 */
//#undef SUNDIALS_MPI_COMM_F2C

/* Mark SUNDIALS API functions for export/import
 * When building shared SUNDIALS libraries under Windows, use
 *      #define SUNDIALS_EXPORT __declspec(dllexport)
 * When linking to shared SUNDIALS libraries under Windows, use
 *      #define SUNDIALS_EXPORT __declspec(dllimport)
 * In all other cases (other platforms or static libraries under
 * Windows), the SUNDIALS_EXPORT macro is empty
 */

/* Only windows seem to require a special SUNDIALS export, but we create if/else
 * for each operating systems for the sake of clarity and future modifications. 
 * */
#if defined(_WIN32) || defined(WIN32) || defined(__CYGWIN__) || defined(__MINGW32__) || defined(__BORLANDC__)
    #define SUNDIALS_EXPORT __declspec(dllexport)
#elif defined(__linux__)
    #define SUNDIALS_EXPORT
#elif defined(__APPLE__) || defined(__MACH__)
    #define SUNDIALS_EXPORT
#else
    #define SUNDIALS_EXPORT
#endif


 
