implicit none
logical,parameter::yes=.true.
integer::i
i=0
do while(yes)
i=i+1
if(i==2) exit
end do
print "(i0)",i
end
