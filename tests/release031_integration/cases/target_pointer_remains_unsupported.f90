! Synthetic release 0.31 composition fixture; not an extracted utility body.
program composition
implicit none
integer,target :: data(2)
integer,pointer :: view(:)
data=[3,4]
view=>data
print *,view
end program
