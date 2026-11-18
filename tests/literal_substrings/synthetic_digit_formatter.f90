program p
implicit none
if(format(1203)/='1203'.or.format(0)/='0') error stop 1
print *, 'digit formatter'
contains
pure function format(n) result(ch)
integer,intent(in)::n
character(20)::ch
integer::temp,digit,j
ch='';temp=n
do j=1,20
 digit=mod(temp,10)+1
 ch="0123456789"(digit:digit)//ch
 temp=temp/10
 if(temp==0) exit
end do
end function
end program
