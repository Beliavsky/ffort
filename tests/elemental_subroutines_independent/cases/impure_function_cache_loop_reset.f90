program elemental_actions
implicit none
integer::aa(2),bb(2),i
aa=1
do i=1,2
bb=compute(aa)
aa=aa+1
end do
print *,bb
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute

end program
