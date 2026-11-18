program alloc
  implicit none
  integer, allocatable :: a(:), b(:,:)
  real(8), allocatable :: w(:)
  integer :: i, st
  allocate(a(5), stat=st)
  print '(i0)', st
  a = [(i*i, i=1,5)]
  a = [a, 36, 49]
  print '(7i4)', a
  print '(l2)', allocated(b)
  allocate(b(2,3))
  b = 1
  b(2,:) = [4,5,6]
  print '(3i3)', transpose(b)
  deallocate(b)
  print '(l2)', allocated(b)
  w = [1.0d0, 2.0d0]
  call grow(w, 4)
  print '(4f5.1)', w
  print '(i0)', size(w)
contains
  subroutine grow(x, n)
    real(8), allocatable, intent(inout) :: x(:)
    integer, intent(in) :: n
    real(8), allocatable :: t(:)
    allocate(t(n))
    t = -1
    t(1:size(x)) = x
    call move_alloc(t, x)
  end subroutine grow
end program alloc
