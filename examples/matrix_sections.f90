module matrix_section_ops
  implicit none
contains
  subroutine increment_column(column)
    integer, intent(inout) :: column(-1:)
    column=column+100
  end subroutine increment_column
end module matrix_section_ops
program matrix_sections
  use matrix_section_ops
  implicit none
  integer :: a(3,4), i, j
  do j=1,4
    do i=1,3
      a(i,j)=10*j+i
    end do
  end do
  ! Overlap-safe rectangular shift, then a strided rank-reducing actual.
  a(:,2:4)=a(:,1:3)
  call increment_column(a(3:1:-1,2))
  print *,a
  print *,a(2,:),size(a(3:1:-1,4:1:-2),1),size(a(3:1:-1,4:1:-2),2)
end program matrix_sections
