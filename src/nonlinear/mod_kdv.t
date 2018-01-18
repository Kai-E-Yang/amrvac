!> Module for including kdv source term in simulations
!> adds -\sum_i \partial_iii \rho over dimensions i
module mod_kdv
  implicit none

  !> source split or not
  logical :: kdv_split= .false.

contains
  !> Read this module's parameters from a file
  subroutine kdv_params_read(files)
    use mod_global_parameters, only: unitpar
    character(len=*), intent(in) :: files(:)
    integer                      :: n

    namelist /kdv_list/ kdv_split

    do n = 1, size(files)
       open(unitpar, file=trim(files(n)), status="old")
       read(unitpar, kdv_list, end=111)
111    close(unitpar)
    end do

  end subroutine kdv_params_read

  !> Initialize the module
  subroutine kdv_init()
    use mod_global_parameters

    call kdv_params_read(par_files)

  end subroutine kdv_init

  !> w[iw]=w[iw]+qdt*S[wCT,qtC,x] where S is the source based on wCT within ixO
  subroutine kdv_add_source(qdt,ixI^L,ixO^L,wCT,w,x,qsourcesplit,active)
    use mod_global_parameters
    use mod_usr_methods

    integer, intent(in)             :: ixI^L, ixO^L
    double precision, intent(in)    :: qdt, x(ixI^S,1:ndim)
    double precision, intent(in)    :: wCT(ixI^S,1:nw)
    double precision, intent(inout) :: w(ixI^S,1:nw)
    logical, intent(in) :: qsourcesplit
    logical, intent(inout) :: active

    integer          :: idir, lx^L,kx^L,jx^L,hx^L,gx^L,fx^L
    double precision :: skdv(ixI^S)

    if(qsourcesplit .eqv. kdv_split) then
      active = .true.
      skdv(ixO^S)=zero
      do idir=1,ndim
       ! The source is based on the time centered wCT
       lx^L=ixO^L+3*kr(idir,^D);
       kx^L=ixO^L+2*kr(idir,^D);
       jx^L=ixO^L+kr(idir,^D);
       hx^L=ixO^L-kr(idir,^D);
       gx^L=ixO^L-2*kr(idir,^D);
       fx^L=ixO^L-3*kr(idir,^D);
       ! centered difference evaluation for -\partial_xxx \rho
       ! warning: needs 3 ghostcells, assumes equidistant grid
       skdv(ixO^S)=skdv(ixO^S)+(-wCT(lx^S,iw_rho)+8.0d0*wCT(kx^S,iw_rho)-13.0d0*wCT(jx^S,iw_rho) &
                           +13.0d0*wCT(hx^S,iw_rho)-8.0d0*wCT(gx^S,iw_rho)+wCT(fx^S,iw_rho)) &
                          /(8.0d0 *dxlevel(idir)**3)
      enddo
      w(ixO^S,iw_rho) = w(ixO^S,iw_rho) - qdt*skdv(ixO^S)
    end if

  end subroutine kdv_add_source

  subroutine kdv_get_dt(w,ixI^L,ixO^L,dtnew,dx^D,x)
    use mod_global_parameters
    use mod_usr_methods

    integer, intent(in)             :: ixI^L, ixO^L
    double precision, intent(in)    :: dx^D, x(ixI^S,1:ndim), w(ixI^S,1:nw)
    double precision, intent(inout) :: dtnew

    double precision :: dxarr(ndim)

    ^D&dxarr(^D)=dx^D;
    dtnew=dtdiffpar*minval(dxarr(1:ndim))**3

  end subroutine kdv_get_dt

end module mod_kdv
