! SPDX-License-Identifier: MIT
program keyword_arguments
    implicit none
    integer :: a(-1:0,3:4), column_totals(2), answer
    logical :: selected(2,2)
    a(:,3)=2
    a(:,4)=5
    selected=.true.
    selected(1,2)=.false.
    column_totals=sum(mask=selected,array=a,dim=1)
    print *,column_totals
    print *,size(dim=2,array=a),lbound(dim=1,array=a)
    print *,difference(right=3,left=10)
    call scale(output=answer,factor=3,value=sum(array=a))
    print *,answer
contains
    integer function difference(left,right) result(value)
        integer,intent(in)::left,right
        value=left-right
    end function difference
    subroutine scale(value,factor,output)
        integer,intent(in)::value,factor
        integer,intent(out)::output
        output=value*factor
    end subroutine scale
end program keyword_arguments
