program p
implicit none
integer::aa(32768),nn
aa=1
nn=32768
print *,91
print *,sum([aa(:nn),aa(:nn),aa(:nn)])
end program p
