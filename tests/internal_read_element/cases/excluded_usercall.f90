program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines="17"
read(lines(f()),*)n
contains
pure integer function f()
f=1
end function
end program
