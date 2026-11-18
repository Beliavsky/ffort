program p
implicit none
integer::aa(3),bb(4),nn
aa(1)=1
aa(2)=2
aa(3)=3
nn=2
bb=[aa(:nn),7,8]
print *,bb
end program p
