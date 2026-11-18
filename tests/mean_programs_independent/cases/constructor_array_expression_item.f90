program p
implicit none
integer::aa(2),bb(5)
aa(1)=2
aa(2)=3
bb=[aa+1,9,aa*2]
print *,bb
end program p
