implicit none
logical::more(1)
integer::i
i=0
more=.true.
do while(more(1))
i=i+1
more(1)=i<3
end do
print "(i0)",i
end
