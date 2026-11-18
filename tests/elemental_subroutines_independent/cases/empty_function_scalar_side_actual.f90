program elemental_actions
implicit none
integer::aa(0),bb(0)
bb=combine(aa,compute(7))
print *,size(bb)
contains
impure elemental integer function compute(xx) result(rr)
integer,intent(in)::xx
print *,xx
rr=xx+10
end function compute
impure elemental integer function combine(xx,yy) result(rr)
integer,intent(in)::xx,yy
print *,xx
rr=xx+yy
end function combine

end program
