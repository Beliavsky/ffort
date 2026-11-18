program independent_ranktwo
implicit none
integer :: aa(2,3),ii,jj
aa=1
ii=2
jj=1
call revise(aa(ii,jj),ii,jj)
print *,aa,ii,jj
contains
subroutine revise(xx,ii,jj)
 integer,intent(inout) :: xx,ii,jj
 ii=1
 jj=3
 xx=7
end subroutine revise
end program independent_ranktwo
