program p
implicit none
integer::aa(3),bb(4),nn
aa=1
nn=2
print *,72
bb=[aa(:nn),7]
print *,bb
end program p
