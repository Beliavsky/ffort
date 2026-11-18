program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines="17"
i=1
n=1
ios=1
read(lines(ios),*,iostat=ios)n
end program
