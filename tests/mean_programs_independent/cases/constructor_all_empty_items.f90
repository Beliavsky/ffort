program p
implicit none
integer::aa(0),bb(0)
bb=[aa,aa]
print *,size(bb),sum([aa])
end program p
