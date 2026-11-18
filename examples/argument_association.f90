module statistics
  use, intrinsic :: iso_fortran_env, only : real64
  implicit none
contains
  subroutine describe(values, average, deviation)
    real(real64), intent(in) :: values(:)
    real(real64), intent(out) :: average, deviation
    integer :: i
    if (size(values) < 2) error stop 'need at least two values'
    average = 0.0_real64
    do i = lbound(values, 1), ubound(values, 1)
      average = average + values(i)
    end do
    average = average / size(values)
    deviation = 0.0_real64
    do i = 1, size(values)
      deviation = deviation + (values(i) - average)**2
    end do
    deviation = sqrt(deviation / (size(values) - 1))
  end subroutine
  pure subroutine center(values, average)
    real(real64), intent(inout) :: values(:)
    real(real64), intent(in) :: average
    values = values - average
  end subroutine
  subroutine increment(value)
    real(real64), intent(inout) :: value
    value = value + 1.0_real64
  end subroutine
end module
program argument_demo
  use statistics
  implicit none
  real(real64) :: data(-2:2), average, deviation
  integer :: i
  do i = -2, 2
    data(i) = i + 3
  end do
  call describe(data, average, deviation)
  print '(a,f12.6)', 'mean: ', average
  print '(a,f12.6)', 'sample standard deviation: ', deviation
  call center(data(2:-2:-1), average)
  call increment(data(0))
  print *, data
end program
