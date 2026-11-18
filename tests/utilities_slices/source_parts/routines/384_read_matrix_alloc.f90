subroutine read_matrix_alloc(xfile,xx,iline_dim,sym,max_row,max_col)
! read matrix xx(;,:) from file xfile that has the dimensions on line iline_dim
character (len=*), intent(in)                         :: xfile
integer          , intent(in)                         :: iline_dim
real(kind=dp)    , intent(out), allocatable           :: xx(:,:)
character (len=*), intent(out), allocatable, optional :: sym(:)
integer          , intent(in) ,              optional :: max_row,max_col
integer                                               :: iline,iu,nrow,ncol
call get_unit_open_file(xfile,iu,"r")
do iline=1,iline_dim-1
   read (iu,*)
end do
read (iu,*) nrow,ncol
if (present(max_row)) nrow = min(nrow,max_row)
if (present(max_col)) ncol = min(ncol,max_col)
! print*,"nrow, ncol=",nrow,ncol !! debug
allocate (xx(nrow,ncol))
if (present(sym)) then
   allocate (sym(ncol))
   read (iu,*) sym
end if
do iline=1,nrow
   read (iu,*) xx(iline,:)
end do
! print*,"shape(xx)=",shape(xx) !! debug
close (iu)
end subroutine read_matrix_alloc
!
