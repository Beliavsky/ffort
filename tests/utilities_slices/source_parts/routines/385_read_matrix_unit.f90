subroutine read_matrix_unit(iu,xx,nlines_skip_init,nlines_skip_after_dim)
! read # of columns and rows from successive lines, then allocate and read rows of matrix
integer      , intent(in)               :: iu
real(kind=dp), intent(out), allocatable :: xx(:,:)
integer      , intent(in) , optional    :: nlines_skip_init ! # of lines to skip at beginning of data file
integer      , intent(in) , optional    :: nlines_skip_after_dim ! # of lines to skip after reading dimenions before reading matrix
integer                                 :: i,ierr,ncol,nrows
call skip_lines_unit(iu,nlines_skip_init)
read (iu,*) ncol
read (iu,*) nrows
call skip_lines_unit(iu,nlines_skip_after_dim)
allocate (xx(nrows,ncol))
xx = -999.0_dp
do i=1,nrows
   read (iu,*,iostat=ierr) xx(i,:)
   if (ierr /= 0) then
      write (*,*) "could not read data for row ",i
      exit
   end if
end do
end subroutine read_matrix_unit
!
