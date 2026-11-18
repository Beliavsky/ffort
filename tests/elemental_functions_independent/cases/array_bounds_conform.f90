program elemental_test
implicit none
integer::aa(-2:0),bb(4:6)
aa(-2)=1
aa(-1)=2
aa(0)=3
bb(4)=4
bb(5)=5
bb(6)=6
print *,combine(aa,bb)
contains
elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::yy,xx
rr=10*xx+yy
end function combine

end program
