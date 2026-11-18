program p
implicit none
integer::aa(-1:1),bb(7)
aa(-1)=10
aa(0)=20
aa(1)=30
bb=[aa,7,aa(1:-1:-1)]
print *,bb
end program p
