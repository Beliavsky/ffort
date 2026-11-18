! Elemental OUT/INOUT association and observable IMPURE array element order.
module transforms
implicit none
contains
    elemental subroutine affine(x, scale, output_value)
        integer, intent(in) :: x, scale
        integer, intent(out) :: output_value
        output_value = x * scale + 1
    end subroutine affine

    impure elemental subroutine record_step(x)
        integer, intent(inout) :: x
        print *, x
        x = x + 100
    end subroutine record_step

    impure elemental integer function traced_square(x) result(y)
        integer, intent(in) :: x
        print *, x
        y = x * x
    end function traced_square
end module transforms

program elemental_subroutines
use transforms, only : affine, record_step, traced_square
implicit none
integer :: values(2,2), mapped(2,2), squared(2,2)
values(1,1)=1
values(2,1)=2
values(1,2)=3
values(2,2)=4
call affine(output_value=mapped,x=values,scale=2)
print *,mapped
! Trace 9, 7, 5, 3: section element order, not base storage order.
call record_step(mapped(2:1:-1,2:1:-1))
print *,mapped
! Separate assignment permits function I/O without recursive PRINT.
squared=traced_square(values)
print *,squared
end program elemental_subroutines
