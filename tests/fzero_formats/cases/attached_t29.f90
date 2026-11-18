module util
  implicit none
  interface show
     module procedure show_i, show_r
  end interface show
contains
  subroutine show_i(x, label)
    integer, intent(in) :: x
    character(len=*), intent(in), optional :: label
    if (present(label)) then
       print '(a,a,i0)', label, ': ', x
    else
       print '(i0)', x
    end if
  end subroutine show_i
  subroutine show_r(x, label)
    real, intent(in) :: x
    character(len=*), intent(in), optional :: label
    if (present(label)) then
       print '(a,a,f0.3)', label, ': ', x
    else
       print '(f0.3)', x
    end if
  end subroutine show_r
end module util
program optional_generic
  use util
  implicit none
  call show(3)
  call show(2.5, 'r')
  call show(7, label='seven')
end program optional_generic
