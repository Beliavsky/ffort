program p
implicit none
integer::aa(4)
aa(1)=1
aa(2)=2
aa(3)=3
aa(4)=4
aa=[aa(4),aa(3),aa(2),aa(1)]
print *,aa
end program p
