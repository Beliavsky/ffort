subroutine alloc_matrix_real(n1,n2,xx,xdef)
integer                   , intent(in)  :: n1,n2
real(kind=dp), allocatable, intent(out) :: xx(:,:)
real(kind=dp), optional   , intent(in)  :: xdef
allocate (xx(n1,n2))
if (present(xdef)) xx = xdef
end subroutine alloc_matrix_real
!
