implicit none
integer::i
i=0
do while(.true.)
i=i+1
if(i==3) exit
end do
print "(i0)",i
end
