program p
implicit none
if(size([integer::])/=0) error stop 1
if(any(shape([real(8)::])/=[0])) error stop 2
if(lbound([integer::],1)/=1.or.ubound([integer::],1)/=0) error stop 3
if(sum([integer(8)::])/=0_8.or.product([integer::])/=1) error stop 4
if(any([logical::]).or..not.all([logical::]).or.count([logical::])/=0) error stop 5
if(kind([real(8)::]+1.0d0)/=8) error stop 6
print *, 'PASS' 
end program
