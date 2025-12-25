using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Knjigoteka.Services.Migrations
{
    /// <inheritdoc />
    public partial class bookStockChange : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "TotalQuantity",
                table: "Books",
                newName: "CentralStock");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "CentralStock",
                table: "Books",
                newName: "TotalQuantity");
        }
    }
}
