implicit none
character(*),parameter::a(2)=["ab","cd"]//trim("! ")
character(*),parameter::b(2)=trim("? ")//["ab","cd"]
print '(a)',a,b
end
